# /workflow/task-finish.tcl
# Indicate that a task has been finished for a particular workflow case.

request create
request set_param task_id -datatype integer
request set_param return_url -datatype text -value "../workspace/index"




set user_id [User::getID]
set db [template::get_db_handle]

# check that the task is still valid
template::query is_valid_task onevalue "
  select content_workflow.can_approve( :task_id, :user_id ) from dual
" 

if { [string equal $is_valid_task f] } {
    template::release_db_handle
    template::forward $return_url
}


# Get the name of the item and of the task
template::query task_info onerow "
  select
    c.object_id, content_item.get_title(c.object_id) title, 
    tr.transition_name
  from
    wf_tasks tk, wf_cases c,
    wf_transitions tr
  where
    tk.task_id = :task_id
  and
    tk.transition_key = tr.transition_key
  and
    tk.workflow_key = tr.workflow_key
  and
    tk.workflow_key = 'publishing_wf'
  and
    c.case_id = tk.case_id
  and
    content_workflow.can_approve( tk.task_id, :user_id ) = 't'
" 

template::release_db_handle


form create task_finish -elements {
    task_id    -datatype integer -widget hidden -param
}

element create task_finish return_url \
	-datatype text \
	-widget hidden \
	-value "../workspace/index" \
	-param

element create task_finish task_name \
	-datatype text \
	-widget inform \
	-value $task_info(transition_name) \
	-label "Task"

element create task_finish title \
	-datatype text \
	-widget inform \
	-value $task_info(title) \
	-label "Title"

element create task_finish msg \
	-datatype text \
	-label "Comment" \
	-widget textarea \
	-html { rows 10 cols 40 wrap physical }

set page_title "Finish a Task"






if { [template::form is_valid task_finish] } {
    
    form get_values task_finish task_id msg

    set ip_address [ns_conn peeraddr]    
    set user_id [User::getID]


    set db [template::begin_db_transaction]

    template::query is_valid_task onevalue "
      select content_workflow.can_approve( :task_id, :user_id ) from dual
    "

    if { [string equal $is_valid_task f] } {
	ns_ora dml $db "abort transaction"
	template::release_db_handle
	template::request::error invalid_task \
		"task-finish.tcl - This task is no longer valid - $task_id"
	return
    }

    template::query workflow_approve dml "
      begin
      content_workflow.approve(
          task_id    => :task_id,
          user_id    => :user_id,
          ip_address => :ip_address,
          msg        => :msg
      );
      end;
    "

    # send email notification to the creator of the item
    workflow::notify_admin_of_finished_task $db $task_id

    template::end_db_transaction
    template::release_db_handle

    # Flush the access cache in order to clear permissions
    content::flush_access_cache $task_info(object_id)

    template::forward $return_url
}
