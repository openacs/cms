<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_permissions">      
      <querytext>

  select * from ( 
    select 
      p.pretty_name, 
      p.privilege, 
      u.party_id as grantee_id,
      n.first_names || ' ' || n.last_name as grantee_name,
      u.email
    from 
      acs_permissions per, acs_privileges p, parties u,
      persons n,
      (select o2.object_id 
         from (select * from acs_objects where object_id = :object_id) o1, 
              acs_objects o2
        where o2.tree_sortkey <= o1.tree_sortkey
          and o1.tree_sortkey like (o2.tree_sortkey || '%')
          and o2.tree_sortkey >= (select case when max(ob2.tree_sortkey) is null 
                                                  then '/' 
                                                  else max(ob2.tree_sortkey) end
                                   from (select * 
                                           from acs_objects 
                                          where object_id = :object_id) ob1,
                                        acs_objects ob2
                                  where ob2.tree_sortkey <= ob1.tree_sortkey
                                    and ob1.tree_sortkey like (ob2.tree_sortkey || '%')
                                    and ob2.security_inherit = 'f')) o
    where
      per.privilege = p.privilege
    and
      per.grantee_id = u.party_id
    and
      per.object_id = o.object_id
    and
      u.party_id = n.person_id
  union
    select
      p.pretty_name, p.privilege, 
      -1 as grantee_id, 'All Users' as grantee_name, '&nbsp;' as email 
    from
      acs_permissions per, acs_privileges p, parties u
    where
      u.party_id = -1
    and
      per.object_id = :object_id
    and
      per.privilege = p.privilege
    and
      per.grantee_id = u.party_id
  ) order by
    grantee_name, privilege
  
      </querytext>
</fullquery>

 
</queryset>
