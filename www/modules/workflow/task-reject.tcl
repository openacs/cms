# /workflow/task-reject.tcl
# Indicate that a task has been rejected for a particular workflow case.

request create
request set_param task_id    -datatype integer
request set_param return_url -datatype text -value "../workspace/index"


set user_id [User::getID]

# check that the task is still valid
template::query get_status is_valid_task onevalue "
  select content_workflow.can_reject( :task_id, :user_id ) from dual
" 

if { [string equal $is_valid_task f] } {
    forward $return_url
}



# Get the name of the item and of the task
template::query get_task_info task_info onerow "
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
    tk.case_id = c.case_id
  and
    content_workflow.can_reject( tk.task_id, :user_id ) = 't'
" 


# get the places I can reject to
template::query get_rejects reject_places multilist "
  select
    trans.transition_name, trans.transition_key
  from
    wf_places src, wf_places dest, wf_tasks t, wf_transitions trans
  where
    src.workflow_key = dest.workflow_key
  and
    src.workflow_key = 'publishing_wf'
  and
    src.workflow_key = trans.workflow_key
  and
    src.place_key = content_workflow.get_this_place( t.transition_key )
  and
    -- for the publishing_wf, past transitions have a lower sort order
    dest.sort_order < src.sort_order
  and
    -- get the transition associated with that place
    content_workflow.get_this_place( trans.transition_key ) = dest.place_key
  and
    t.task_id = :task_id
  order by
    dest.sort_order desc
" 

# Create the form

form create reject -elements {
    task_id -datatype integer -widget hidden -param
}

element create reject return_url \
	-datatype text \
	-widget hidden \
	-value "../workspace/index" \
	-param

element create reject task_name \
	-datatype text \
	-widget inform \
	-value $task_info(transition_name) \
	-label "Task"

element create reject title \
	-datatype text \
	-widget inform \
	-value $task_info(title) \
	-label "Title"

element create reject msg \
	-datatype text \
	-label "Comment" \
	-widget textarea  \
	-html { rows 10 cols 40 wrap physical }

element create reject transition_key \
	-datatype keyword \
	-widget select \
	-label "Regress To" \
	-options $reject_places

set page_title "Reject a Task"








# Process the form
if { [template::form is_valid reject] } {
    
    form get_values reject task_id msg transition_key

    set ip_address [ns_conn peeraddr]    
    set user_id [User::getID]

    db_transaction {
        # check that the task is still valid
        template::query is_valid_task onevalue "
             select content_workflow.can_reject( :task_id, :user_id ) from dual" 

        if { [string equal $is_valid_task f] } {
            db_abort_transaction
            template::request::error invalid_task \
		"task-reject.tcl - invalid task - $task_id"
            return
        }

        db_exec_plsql workflow_reject "
                      begin
                        content_workflow.reject(
                             task_id        => :task_id,
                             user_id        => :user_id,
                             ip_address     => :ip_address,
                             transition_key => :transition_key,
                             msg            => :msg
                         );
                       end;"
    }

    # Flush the access cache in order to clear permissions
    content::flush_access_cache $task_info(object_id)

    forward $return_url
}
