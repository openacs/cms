request create
request set_param transition -datatype keyword -value "all"


if { ![string equal $transition "all"] } {
    template::query get_transitoin_name transition_name onevalue "
      select transition_name
        from wf_transitions
        where transition_key = :transition
        and workflow_key = 'publishing_wf'"

    set transition_sql "and ca.transition_key = :transition"

} else {
    set transition_name "All Tasks"
    set transition_sql ""
}


set date_format "'Mon. DD, YYYY HH24:MI:SS'"

template::query get_overdue_tasks overdue_tasks multirow "
  select
    ca.transition_key, transition_name, ca.party_id, 
    item_id, content_item.get_title(item_id) as title,
    nvl(party.name(ca.party_id),person.name(ca.party_id)) as assigned_party,
    to_char(dead.deadline,'Mon. DD, YYYY') as deadline_pretty,
    content_workflow.get_status(c.case_id, ca.transition_key) as status
  from 
    wf_transitions trans, wf_cases c, wf_case_deadlines dead, 
    wf_case_assignments ca, cr_items i
  where 
    c.case_id = dead.case_id
  and
    c.case_id = ca.case_id
  and
    ca.transition_key = dead.transition_key
  and
    trans.transition_key = ca.transition_key
  and
    c.workflow_key = 'publishing_wf'
  and
    c.workflow_key = trans.workflow_key
  and
    c.state = 'active'
  and 
    c.object_id = i.item_id
  and
    content_workflow.is_overdue(c.case_id, ca.transition_key) = 't'
  $transition_sql
  order by
    transition_name, dead.deadline desc, title, assigned_party"


set page_title "Outstanding Workflow Tasks - $transition_name"
