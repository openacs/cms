# workflow.tcl


request create
request set_param transition -datatype keyword -value "all"


if { [string equal $transition "all"] } {
    set transition_name "All Tasks"
    set transition_sql ""
} else {

    template::query get_name transition_name onevalue "
      select 
        transition_name 
      from 
        wf_transitions
      where 
        transition_key = :transition
      and 
        workflow_key = 'publishing_wf'
    " -cache "workflow_transition_name $transition" -persistent \
      -timeout 3600

    if { [template::util::is_nil transition_name] } {
	ns_log notice "workflow.tcl - Bad transition - $transition"
	forward "workflow"
    }
    set transition_sql "and ca.transition_key = :transition"
}



set date_format "'Mon. DD, YYYY HH24:MI:SS'"



template::query get_active active_tasks multirow "
  select
    t.transition_key, transition_name, 
    item_id, content_item.get_title(item_id) as title,
    t.state, ca.party_id,
    nvl(party.name(ca.party_id),person.name(ca.party_id)) as assigned_party,
    holding_user,
    person.name(holding_user) as holding_user_name,
    to_char(hold_timeout,'Mon. DD, YYYY') as hold_timeout_pretty,
    to_char(deadline,'Mon., DD, YYYY') as deadline_pretty,
    to_char(enabled_date,$date_format) as enabled_date_pretty, 
    to_char(started_date,$date_format) as started_date_pretty,
    content_workflow.is_overdue(c.case_id, t.transition_key) as is_overdue
  from
    wf_tasks t, wf_transitions trans, cr_items i,
    wf_cases c, wf_case_assignments ca
  where
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.case_id = t.case_id
  and
    c.case_id = ca.case_id
  and
    c.state = 'active'
  and
    -- the workflow item is a content item
    c.object_id = i.item_id
  and
    t.transition_key = trans.transition_key
  and
    ca.transition_key = t.transition_key
  and
    t.state in ('started','enabled')
  $transition_sql
  order by
    trans.sort_order, title, assigned_party, deadline desc, state
"

template::query get_waiting awaiting_tasks multirow "
  select
    ca.transition_key, transition_name, ca.party_id,
    item_id, content_item.get_title(item_id) as title,
    nvl(party.name(ca.party_id),person.name(ca.party_id)) as assigned_party,
    to_char(dead.deadline,'Mon.DD, YYYY') as deadline_pretty,
    content_workflow.is_overdue(c.case_id, ca.transition_key) as is_overdue
  from
    wf_cases c, wf_case_assignments ca, wf_case_deadlines dead,
    wf_transitions trans, cr_items i
  where
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.object_id = i.item_id
  and
    c.case_id = ca.case_id
  and
    c.case_id = dead.case_id
  and
    ca.transition_key = trans.transition_key
  and
    dead.transition_key = trans.transition_key
  and
    c.state = 'active'
  and
    -- non active task
    not exists ( select 1
                 from 
                   wf_tasks
                 where
                   state in ('enabled','started')
                 and
                   case_id = c.case_id
                 and
                   transition_key = ca.transition_key )
  and
    -- its finished
    content_workflow.is_finished(c.case_id, ca.transition_key) = 'f'
  -- ca.transition_key = transition 
  $transition_sql
  order by
    trans.sort_order, title, assigned_party, dead.deadline desc"

set page_title "Workflow Tasks - $transition_name"
