<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="check_admin">      
      <querytext>
      
  select 
    cms_permission__permission_p (:module_id, :user_id, 'cm_admin')
  from
    dual
      </querytext>
</fullquery>

 
<fullquery name="check_perm">      
      <querytext>
      
  select 
    cms_permission__permission_p (:module_id, :user_id, 'cm_perm')
  from
    dual
      </querytext>
</fullquery>

 
<fullquery name="get_info1">      
      <querytext>
      
    select 
      g.group_id, g.group_name, p.email, p.url,
      coalesce((select 'f'  where exists (
            select 1 from acs_rels 
              where object_id_one = :id 
              and rel_type in ('composition_rel', 'membership_rel'))),
          't') as is_empty 
    from 
      groups g, parties p
    where
      g.group_id = :id
    and
      p.party_id = :id
      </querytext>
</fullquery>

 
</queryset>