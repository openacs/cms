<?xml version="1.0"?>
<queryset>

<fullquery name="get_caseinfo">      
      <querytext>
      select case_id, initcap(state) state
           from wf_cases where object_id = :item_id
      </querytext>
</fullquery>

 
<fullquery name="get_status">      
      <querytext>
      select case when count(*) = 0 then 'no' else 'yes' end
               from wf_case_assignments
               where case_id = :case_id 
               and transition_key = :transition_key 
               and party_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
