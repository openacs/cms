<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="getSortedPaths.">      
      <querytext>
      select 
                         item_id, 
                         content_item.get_path(item_id, :sorted_paths_root_id) as item_path,
                         content_type as item_type
                       from 
                         cr_items
                       where
                         item_id in ($sql_id_list)
                       order by item_path
      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.gcf_get_child_folders">      
      <querytext>
      
        select
	  :mount_point as mount_point,
	  r.name, 
          r.item_id,
          '' as children,
	  nvl((select 't' from dual where exists
	    (select 1 from cr_folders f_child, cr_resolved_items r_child
	       where r_child.parent_id = r.resolved_id
		 and f_child.folder_id = r_child.resolved_id)), 'f') expandable,
	  r.is_symlink symlink, 
          0 update_time
	from
	  cr_folders f, cr_resolved_items r
	where
	  r.parent_id = :id
	and
	  r.resolved_id = f.folder_id
	order by
	  name
      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.grfi_get_root_id">      
      <querytext>
      
            select content_template.get_root_folder() from dual
      </querytext>
</fullquery>

 
<fullquery name="getSortedPaths.gri_get_root_id">      
      <querytext>
      
            select content_item.get_root_folder() from dual
      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.gtt_get_tree_types">      
      <querytext>
      
          select
            lpad(' ', level, '-') || pretty_name as label,
            object_type as value
          from
            acs_object_types t
          connect by
            supertype = prior object_type
          start with
            object_type = 'content_revision'
        
      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.gcf_get_child_folders">      
      <querytext>
      
        select
	  :mount_point as mount_point,
	  r.name, 
          r.item_id,
          '' as children,
	  nvl((select 't' from dual where exists
	    (select 1 from cr_folders f_child, cr_resolved_items r_child
	       where r_child.parent_id = r.resolved_id
		 and f_child.folder_id = r_child.resolved_id)), 'f') expandable,
	  r.is_symlink symlink, 
          0 update_time
	from
	  cr_folders f, cr_resolved_items r
	where
	  r.parent_id = :id
	and
	  r.resolved_id = f.folder_id
	order by
	  name
      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.gcc_get_child_folders">      
      <querytext>
      
                     select 
                     :module_name as mount_point,
                     content_keyword.get_heading(keyword_id) as name, 
                     keyword_id, 
                     '' as children,
                     NVL( (select 't' from dual 
                             where exists (
                               select 1 from cr_keywords k2
                                 where k2.parent_id = k.keyword_id
                                   and content_keyword.is_leaf(k2.keyword_id) = 'f')),
                           'f') as expandable,
                     'f' as symlink,
                     0 as update_time           
                   from 
                     cr_keywords k
                   where 
                     $where_clause
                   and
                     content_keyword.is_leaf(keyword_id) = 'f'
                   order by 
                     name
      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.gcf_get_child_folders">      
      <querytext>
      
        select
	  :mount_point as mount_point,
	  r.name, 
          r.item_id,
          '' as children,
	  nvl((select 't' from dual where exists
	    (select 1 from cr_folders f_child, cr_resolved_items r_child
	       where r_child.parent_id = r.resolved_id
		 and f_child.folder_id = r_child.resolved_id)), 'f') expandable,
	  r.is_symlink symlink, 
          0 update_time
	from
	  cr_folders f, cr_resolved_items r
	where
	  r.parent_id = :id
	and
	  r.resolved_id = f.folder_id
	order by
	  name
      </querytext>
</fullquery>

<partialquery name="getSortedPaths.gsp_get_sorted_paths">
	<querytext>
	               select 
                         item_id, 
                         content_item.get_path(item_id, :sorted_paths_root_id) as item_path,
                         content_type as item_type
                       from 
                         cr_items
                       where
                         item_id in ($sql_id_list)
                       order by item_path
	</querytext>
</partialquery>

<partialquery name="getSortedPaths.gsp_get_query">
	<querytext>

          select 
            keyword_id as item_id,
            content_keyword.get_path(keyword_id) as item_path,
            'content_keyword' as item_type
          from
            cr_keywords
          where 
            keyword_id in ($sql_id_list)

	</querytext>
</partialquery>

<partialquery name="getSortedPaths.gsp_get_sort_paths">
	<querytext>

          select 
            o.object_id as item_id,
            o.object_type || ': ' || acs_object.name(o.object_id) as item_path,
            o.object_type as item_type
          from
            acs_objects o, parties p
          where
            o.object_id = p.party_id
          and
            o.object_id in ($sql_id_list)
          order by
            item_path

	</querytext>
</partialquery>

</queryset>
