# /workspace/index.tcl

request create
request set_param id -datatype keyword -optional
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value workspace

set user_id [User::getID]


# first part of the where clause gets all assignments for the individual
# and for any groups to which the individual belongs.


template::query get_workspace_items items multirow "
  select
    types.pretty_name, 
    obj.object_id item_id, 
    content_item.get_title(obj.object_id) title,
    task.task_id,
    task.holding_user,
    task.state,
    assign.case_id, 
    trans.transition_name, trans.transition_key,
    to_char(dead.deadline,'Mon. DD, YYYY') deadline,
    content_workflow.can_reject(task.task_id, :user_id) can_reject,
    content_workflow.approve_string(task.task_id, :user_id) approve_string
  from
    acs_object_types types,
    acs_objects obj,
    wf_case_assignments assign,
    wf_transitions trans, 
    wf_tasks task,
    wf_cases case,
    wf_case_deadlines dead
  where 
    dead.case_id = case.case_id
  and
    dead.transition_key = task.transition_key
  and
    assign.party_id = :user_id
  and
    assign.case_id = task.case_id
  and
    assign.transition_key = task.transition_key
  and (
    task.state = 'enabled'
    or (task.state = 'started' and task.holding_user = :user_id)
  ) and
    task.transition_key = trans.transition_key
  and
    assign.case_id = case.case_id
  and
    case.object_id = obj.object_id
  and
    types.object_type = content_item.get_content_type(obj.object_id)
  order by
    dead.deadline"


# don't cache this page
#ns_set put [ns_conn outputheaders] Pragma "No-cache"





