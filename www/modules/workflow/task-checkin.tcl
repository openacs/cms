# /task-checkin.tcl
# This is form for checking in an item that this user holds

request create
request set_param task_id    -datatype integer
request set_param return_url -datatype text    -value "../workspace/index"


set user_id [User::getID]

# check that the task is still valid
query is_valid_task onevalue "
  select content_workflow.can_approve( :task_id, :user_id ) from dual
" 

if { [string equal $is_valid_task f] } {
  template::release_db_handle
  template::forward $return_url
}


# task info

template::query get_task_info task_info onerow "
  select
    c.object_id, tr.transition_name,
    content_item.get_title(c.object_id) title,
    tk.holding_user as holding_user, 
    to_char(tk.hold_timeout,'Mon. DD, YYYY') hold_timeout,
    content_workflow.get_holding_user_name(tk.task_id) holding_user_name
  from
    wf_tasks tk, wf_transitions tr, wf_cases c
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.case_id = c.case_id
" 


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

element create task_start msg \
        -datatype text \
        -label "Comment" \
        -widget textarea \
        -html { rows 10 cols 40 wrap physical }



if { [form is_valid task_start] } {
    
    form get_values task_start task_id msg
    
    set ip_address [ns_conn peeraddr]    
    set user_id [User::getID]

    set db [template::begin_db_transaction]

    # check that the task is still valid
    template::query get_task_status is_valid_task onevalue "
      select content_workflow.can_approve( :task_id, :user_id ) from dual
    " 

    if { [string equal $is_valid_task f] } {
	db_dml abort "abort transaction"
	template::request::error invalid_task \
		"task-checkin.tcl - invalid task - $task_id"
	return
    }

    db_exec_plsql workflow_checkin "
      begin
      content_workflow.checkin(
          task_id      => :task_id,             
          user_id      => :user_id,
          ip_address   => :ip_address,
          msg          => :msg
      );
      end;
    "    
    template::forward $return_url
}
