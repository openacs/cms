# Display a list of currently defined workflows

request create
request set_param id -datatype keyword -optional
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -value workflow

set db [template::get_db_handle]

# workflow totals

template::query wf_stats onerow "
  select
    count( decode(content_workflow.is_finished(c.case_id, transition_key),
             'f',1,null)
    ) as total_count,
    count( decode(content_workflow.is_overdue(c.case_id, transition_key),
             't',1,null)
    ) as overdue_count,
    count( decode(content_workflow.is_active(c.case_id, transition_key),
             't',1,null)
    ) as active_count,
    count( decode(content_workflow.is_checked_out(c.case_id, transition_key),
             't',1,null)
    ) as checkout_count
  from
    wf_cases c, wf_transitions trans
  where
    c.workflow_key = trans.workflow_key
  and
    c.workflow_key = 'publishing_wf'
  and
    c.state = 'active'
" 
    
set sql "
  select 
    trans.transition_key, transition_name, sort_order,
    count(transition_name) as transition_count,
    count(decode (
            content_workflow.is_overdue(c.case_id, trans.transition_key),
            't',1,null)
         ) as overdue_count,
    count(decode (
            content_workflow.is_active(c.case_id, trans.transition_key),
            't',1,null)
         ) as active_count,
    count( decode(
             content_workflow.is_checked_out(c.case_id, trans.transition_key),
             't',1,null)
         ) as checkout_count
  from
    wf_cases c, wf_transitions trans
  where
    trans.workflow_key = c.workflow_key
  and
    trans.workflow_key = 'publishing_wf'
  and
    c.state in ('active')
  and
    -- don't include tasks that have been finished or canceled
    content_workflow.is_finished(c.case_id, trans.transition_key) = 'f'
  group by
    sort_order, transition_name, trans.transition_key
"

# workflow tasks by transition state: content items, overdue items
template::query transitions multirow $sql 



# workflow tasks by user: content items, overdue items
query user_tasks multirow "
  select
    p.person_id, p.first_names, p.last_name,
    count(transition_name) as transition_count,
    count(decode (
            content_workflow.is_overdue(c.case_id, t.transition_key),
            't',1,null)
         ) as overdue_count,
    count(decode (
            content_workflow.is_active(c.case_id, t.transition_key),
            't',1,null)
         ) as active_count,
    count( decode(
             content_workflow.is_checked_out(c.case_id, t.transition_key, ca.party_id),
             't',1,null)
         ) as checkout_count
  from
    wf_cases c, wf_case_assignments ca, 
    wf_transitions t, persons p
  where
    t.workflow_key = 'publishing_wf'
  and
    t.workflow_key = c.workflow_key
  and
    c.state = 'active'
  and
    c.case_id = ca.case_id
  and
    ca.transition_key = t.transition_key
  and
    p.person_id = ca.party_id
  and
    -- don't include tasks that have been finished or canceled
    content_workflow.is_finished(c.case_id, t.transition_key) = 'f'
  group by
    first_names, last_name, person_id 
" 

template::release_db_handle

set page_title "Workflow Statistics"
