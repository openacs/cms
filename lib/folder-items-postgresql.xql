<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_folder_contents_paginate">      
      <querytext>

  select
    r.item_id, v.title, last_modified
  from 
    cr_items i
        LEFT OUTER JOIN
    cr_revisions v ON i.latest_revision = v.revision_id
        LEFT OUTER JOIN
    cr_revisions u ON i.live_revision = u.revision_id
        LEFT OUTER JOIN
    cr_folders f ON i.item_id = f.folder_id, 
    cr_resolved_items r, acs_objects o
  where
    r.parent_id = :folder_id
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
   [template::list::orderby_clause -name folder_items -orderby]

      </querytext>
</fullquery>

<fullquery name="get_folder_contents">      
      <querytext>

  select
    r.item_id, r.item_id as id, v.revision_id, r.resolved_id, r.is_symlink,
    r.name, i.parent_id, i.content_type, i.publish_status, u.publish_date,
    coalesce(trim(
      case when i.content_type = 'content_symlink' then r.label
           when i.content_type = 'content_folder' then f.label
	   else coalesce(v.title, i.name) end),'-') as title,
    t.pretty_name as pretty_content_type, last_modified, 
    v.content_length
  from 
    cr_items i
        LEFT OUTER JOIN
    cr_revisions v ON i.latest_revision = v.revision_id
        LEFT OUTER JOIN
    cr_revisions u ON i.live_revision = u.revision_id
        LEFT OUTER JOIN
    cr_folders f ON i.item_id = f.folder_id, 
    cr_resolved_items r, acs_objects o, acs_object_types t
  where
    r.parent_id = :folder_id
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
   [template::list::page_where_clause -and -name folder_items -key r.item_id]
   [template::list::orderby_clause -name folder_items -orderby]

      </querytext>
</fullquery>

</queryset>