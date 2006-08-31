<?xml version="1.0"?>

<queryset>

<fullquery name="get_revisions">      
      <querytext>
     
  select 
    revision_id, 
    r.title, 
    description,
    content_length,
    publish_date,
    coalesce(o.modifying_user,o.creation_user) as author_id
  from 
    cr_revisions r join acs_objects o on (r.revision_id = o.object_id)
  where 
    r.item_id = :item_id

      </querytext>
</fullquery>

 
</queryset>
