<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="write_content">      
      <querytext>
      
  select
        [ad_decode $storage_type file "'[cr_fs_path]' || filename" content] as content
  from 
    cr_revisions
  where
    revision_id = $revision_id

      </querytext>
</fullquery>

 
<fullquery name="get_iteminfo">      
      <querytext>
      
  select
    item_id, mime_type, content_revision.is_live( revision_id ) is_live
  from
    cr_revisions
  where
    revision_id = :revision_id

      </querytext>
</fullquery>

 
</queryset>
