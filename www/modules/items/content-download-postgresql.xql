<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="write_content">      
      <querytext>

  select
    case when i.storage_type = 'file' 
              then '[cr_fs_path]' || r.content 
         when i.storage_type = 'lob'
              then lob::text
        else r.content end as content, i.storage_type 
  from 
    cr_revisions r, cr_items i
  where
    r.item_id = i.item_id
  and 
    revision_id = $revision_id

      </querytext>
</fullquery>

 
<fullquery name="get_iteminfo">      
      <querytext>
      
  select
    item_id, mime_type, content_revision__is_live( revision_id ) as is_live
  from
    cr_revisions
  where
    revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>
