<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="workflow::notify_of_assignments.noa_get_assignments">      
      <querytext>
      
      select
        transition_name, party_id, 
        content_item__get_title(i.item_id) title,
        to_char(cd.deadline,'Month DD, YYYY') deadline_pretty,
        coalesce(party__name(party_id),person__name(party_id)) name
      from
        wf_transitions t, cr_items i,
        wf_cases c, wf_case_assignments ca, wf_case_deadlines cd
      where
        c.workflow_key = 'publishing_wf'
      and
        c.workflow_key = t.workflow_key
      and
        ca.transition_key = t.transition_key
      and
        ca.transition_key = cd.transition_key
      and
        c.case_id = ca.case_id
      and
        c.case_id = cd.case_id
      and
        c.case_id = :case_id
      and
        c.state = 'active'
      and
        c.object_id = i.item_id
    
      </querytext>
</fullquery>

 
<fullquery name="workflow::notify_admin_of_new_tasks.naont_get_assignments">      
      <querytext>
      
      select
        o.creation_user as admin_id, transition_name, party_id, 
        content_item__get_title(i.item_id) title,
        to_char(deadline,'Month DD, YYYY') deadline_pretty,
        coalesce(party__name(party_id),person__name(party_id)) name,
        coalesce(party__name(admin_id),person__name(admin_id)) admin_name
      from
        wf_cases c, wf_case_assignments ca, wf_case_deadlines cd,
        wf_transitions t, cr_items i, acs_objects o
      where
        c.workflow_key = 'publishing_wf'
      and
        c.workflow_key = t.workflow_key
      and
        c.case_id = ca.case_id
      and
        c.case_id = cd.case_id
      and
        c.case_id = :case_id
      and
        ca.transition_key = t.transition_key
      and
        ca.transition_key = cd.transition_key
      and
        t.transition_key = :transition_key
      and
        c.state = 'active'
      and
        c.object_id = i.item_id
      and
        c.case_id = o.object_id
    
      </querytext>
</fullquery>

 
<fullquery name="workflow::notify_admin_of_finished_task.naoft_get_name">      
      <querytext>
      
      select person__name( :user_id ) 
    
      </querytext>
</fullquery>

 
<fullquery name="workflow::notify_admin_of_finished_task.naoft_get_task_info">      
      <querytext>
      
      select
        transition_name, 
        content_item__get_title(i.item_id) as title,
        o.creation_user as admin_id,
        person__name( o.creation_user ) as admin_name,
        to_char(current_timestamp,'Mon DD, YYYY') as today
      from
        wf_tasks t, wf_transitions tr, wf_cases c,
        cr_items i, acs_objects o
      where
        tr.transition_key = t.transition_key
      and
        tr.workflow_key = t.workflow_key
      and
        t.case_id = c.case_id
      and
        c.object_id = i.item_id
      and
        i.item_id = o.object_id
      and
        t.task_id = :task_id
    
      </querytext>
</fullquery>

 
<fullquery name="workflow::check_wf_permission.cwp_touch_info">      
      <querytext>
      
      select
        content_workflow__can_touch( :item_id, :user_id )
      from
        dual
    
      </querytext>
</fullquery>

 
</queryset>