<?xml version="1.0"?>
<queryset>

<fullquery name="get_filename">      
      <querytext>
      
  select
    name as file_name,
    storage_type
  from
    cr_items
  where
    item_id = ( select
                  item_id
                from
                  cr_revisions
                where
                  revision_id = :revision_id )

      </querytext>
</fullquery>

 
</queryset>
