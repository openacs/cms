# Display the next action to perform on this object, if any

# If the task is currently being performed by someone else, display that
# If the task is not currently being performed and you are assigned to it,
# have links to either check out or perform (finish) the task.

# requires: item_id

request create -params {
  item_id     -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}


# Check permissions
content::check_access $item_id cm_item_workflow \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# Look up the workflow associated with this item, if any:

#set query "select case_id, initcap(toplevel_state) state
#           from wf_cases where object_id = :item_id"

template::query get_caseinfo caseinfo onerow "select case_id, initcap(state) state
           from wf_cases where object_id = :item_id"

# Look up the enabled or started transition for this workflow, if any: 

if { ! [template::util::is_nil caseinfo] } {

  set case_id $caseinfo(case_id)

  template::query get_transinfo transinfo onerow "select k.transition_key, k.task_id, t.transition_name,
             k.holding_user, 
             content_workflow.get_holding_user_name(k.task_id) hold_name
             from wf_tasks k, wf_transitions t
	     where k.case_id = :case_id 
             and k.state in ('enabled', 'started')
             and k.transition_key = t.transition_key"

  # Determine whether the current user is assigned to the active transition

  if { [array exists transinfo] } {

    set user_id [User::getID]
    set transition_key $transinfo(transition_key)

    template::query get_status is_assigned onevalue "select decode(count(*), 0, 'no', 'yes')
               from wf_case_assignments
               where case_id = :case_id 
               and transition_key = :transition_key 
               and party_id = :user_id"

    # if eligible, add a link to complete this task
    if { $is_assigned } {
      template::query get_deadline deadlline onevalue "select to_char(deadline, 'DD MON') deadline 
		 from wf_case_deadlines 
		 where case_id = :case_id 
                 and transition_key = :transition_key"
    }
  }
}


set return_url "../items/index?item_id=$item_id&mount_point=$mount_point"
