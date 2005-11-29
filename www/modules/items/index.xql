<?xml version="1.0"?>
<queryset>

<fullquery name="get_info">      
      <querytext>
      
  select 
    i.content_type, i.latest_revision, r.title, 
    r.description, o.pretty_name as type_pretty_name
  from 
    cr_items i, cr_revisions r, acs_object_types o
  where 
   i.item_id = :item_id
  and 
   r.revision_id = content_item__get_best_revision(:item_id)
  and 
   i.content_type = o.object_type

      </querytext>
</fullquery>

</queryset>
