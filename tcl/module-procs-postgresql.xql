<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="cm::modules::getChildFolders.gcf_get_child_folders">      
      <querytext>
      
        select
	  :mount_point as mount_point,
	  r.name, 
          r.item_id,
          '' as children,
	  coalesce((select 't'  where exists
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

 
<fullquery name="cm::modules::templates::getRootFolderId.grfi_get_root_id">
      <querytext>
      
            select content_template__get_root_folder(null) 
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::sitemap::getRootFolderID.grfi_get_root_id">      
      <querytext>
      
            select content_item__get_root_folder(null) 
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::types::getTreeTypes.gtt_get_tree_types">      
      <querytext>
      FIX ME CONNECT BY

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


<fullquery name="cm::modules::types::getChildFolders.gcf_get_child_folders">      
      <querytext>

		   select
                     :module_name as mount_point,
                     t.pretty_name, 
                     t.object_type,
                     '' as children,
                     ( CASE WHEN
                           (select count(*) from acs_object_types
                            where supertype = t.object_type) = 0
                       THEN 'f' ELSE 't' END ) as expandable,
                     'f' as symlink, 
                     0 as update_time
                   from 
                     acs_object_types t
                   where 
                     supertype = :id
                   order by 
                     t.pretty_name

      </querytext>
</fullquery>

 
<fullquery name="getChildFolders.gcc_get_child_folders">      
      <querytext>
      
                     select 
                     :module_name as mount_point,
                     content_keyword__get_heading(keyword_id) as name, 
                     keyword_id, 
                     '' as children,
                     (CASE WHEN (
                                 select 1 from cr_keywords k2
                                 where k2.parent_id = k.keyword_id
                                   and content_keyword__is_leaf(k2.keyword_id) = 'f')
                                 ) = 1 THEN 't' ELSE 'f' END
                      ) as expandable,
                     'f' as symlink,
                     0 as update_time           
                   from 
                     cr_keywords k
                   where 
                     $where_clause
                   and
                     content_keyword__is_leaf(keyword_id) = 'f'
                   order by 
                     name
      </querytext>
</fullquery>


<partialquery name="cm::modules::sitemap::getSortedPaths.gsp_get_sorted_paths">
	<querytext>
	               select 
                         item_id, 
                         content_item__get_path(item_id, :sorted_paths_root_id) as item_path,
                         content_type as item_type
                       from 
                         cr_items
                       where
                         item_id in ($sql_id_list)
                       order by item_path
	</querytext>
</partialquery>


<partialquery name="cm::modules::categories::getSortedPaths.gsp_get_query">
	<querytext>

          select 
            keyword_id as item_id,
            content_keyword__get_path(keyword_id) as item_path,
            'content_keyword' as item_type
          from
            cr_keywords
          where 
            keyword_id in ($sql_id_list)

	</querytext>
</partialquery>

<partialquery name="cm::modules::users::getSortedPaths.gsp_get_sort_paths">
	<querytext>

          select 
            o.object_id as item_id,
            o.object_type || ': ' || acs_object__name(o.object_id) as item_path,
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