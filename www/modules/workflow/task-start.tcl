# This is form for checking out an item or stealing the lock from
# another assigned user.

request create
request set_param task_id    -datatype integer
request set_param return_url -datatype text -value "../workspace/index"

set user_id [User::getID]
set db [template::get_db_handle]

# make sure the task hasn't expired yet
template::query is_valid_task onevalue "
  select content_workflow.can_start( :task_id, :user_id ) from dual
" 

# if the task is no longer valid, go to My Tasks page
if { [string equal $is_valid_task f] } {
  template::release_db_handle
  template::forward $return_url
}


# task info
template::query task_info onerow "
  select
    c.object_id, tr.transition_name,
    content_item.get_title(c.object_id) title,
    tk.holding_user as holding_user, 
    to_char(tk.hold_timeout,'Mon. DD, YYYY') hold_timeout,
    content_workflow.get_holding_user_name(tk.task_id) holding_user_name
  from
    wf_tasks tk,
    wf_transitions tr,
    wf_cases c
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.case_id = c.case_id
" 

template::release_db_handle

set holding_user $task_info(holding_user)

form create task_start -elements {
    task_id -datatype integer -widget hidden -param
}


element create task_start return_url \
	-datatype text \
	-widget hidden \
	-value "../workspace/index" \
	-param

element create task_start task_name \
        -datatype text \
        -widget inform \
        -value $task_info(transition_name) \
        -label "Task"

element create task_start title \
        -datatype text \
        -widget inform \
        -value $task_info(title) \
        -label "Title"

# add holding user info to the form (if any)
if { ![template::util::is_nil holding_user] } {

    element create task_start holding_user_name \
            -datatype text \
            -widget inform \
            -value $task_info(holding_user_name) \
            -label "Held by"

    element create task_start hold_timeout \
            -datatype text \
            -widget inform \
            -value $task_info(hold_timeout) \
            -label "Held until"

    if { $holding_user != $user_id } {
        set page_title "Steal a Task"
    }
}

element create task_start hold_date \
        -datatype date \
        -widget date \
        -label "Hold Item Until:"

element create task_start msg \
        -datatype text \
        -label "Comment" \
        -widget textarea \
        -html { rows 10 cols 40 wrap physical }



if { ![info exists page_title] } {
    set page_title "Start a Task"
}

if { [form is_request task_start] } {
    element set_properties task_start hold_date -value [util::date today]
}

if { [form is_valid task_start] } {
    
    form get_values task_start task_id msg hold_date
    set hold_timeout_sql [util::date::get_property sql_date $hold_date]
    
    set ip_address [ns_conn peeraddr]    
    set user_id [User::getID]

    set db [template::begin_db_transaction]

    # check that task has not expired, if it has display error msg
    template::query is_valid_task onevalue "
      select content_workflow.can_start( :task_id, :user_id ) from dual
    " 

    if { [string equal $is_valid_task f] } {
	ns_ora dml $db "abort transaction"
	template::release_db_handle
	template::request::error invalid_task \
		"task-start.tcl - invalid task - $task_id"
	return
    }

    template::query workflow_checkout dml "
      begin
      content_workflow.checkout(
          task_id      => :task_id,             
          hold_timeout => $hold_timeout_sql,
          user_id      => :user_id,
          ip_address   => :ip_address,
          msg          => :msg
      );
      end;
    "

    template::end_db_transaction
    template::release_db_handle
    
    template::forward $return_url
}