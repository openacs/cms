<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cm::modules::users::getSortedPaths.users_get_paths">      
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
</fullquery>

<fullquery name="cm::modules::sitemap::getSortedPaths.sitemap_get_name">      
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

<fullquery name="cm::modules::categories::getSortedPaths.get_paths">      
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
</fullquery>


<fullquery name="cm::modules::getChildFolders.module_get_result">      
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

 
<fullquery name="cm::modules::templates::getRootFolderID.template_get_root_id">      
      <querytext>
      
            select content_template.get_root_folder() from dual
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::sitemap::getRootFolderID.sitemap_get_root_id">      
      <querytext>
      
            select content_item.get_root_folder() from dual
      </querytext>
</fullquery>

 
<fullquery name="cm::modules::types::getTypesTree.types_get_result">      
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

 
<fullquery name="cm::modules::types::getChildFolders.get_result">      
      <querytext>
      select
                     :module_name as mount_point,
                     t.pretty_name, 
                     t.object_type,
                     '' as children,
                     NVL(
                      (select 't' from dual 
                        where exists (select 1 from acs_object_types
                          where supertype = t.object_type)),
                      'f'
                     ) as expandable,
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

 
<fullquery name="cm::modules::categories::getChildFolders.category_get_children">      
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

 
<fullquery name="cm::modules::users::getChildFolders.users_get_result">      
      <querytext>
      select
                     :module_name as mount_point,
                     g.group_name as name, 
                     g.group_id, '' as children,
                     NVL(
                      (select 't' from dual 
                        where exists (
                          select 1 from group_component_map m2
                          where m2.group_id = g.group_id)),
                      'f' 
                     ) as expandable,
                     'f' as symlink,
                     0 as update_time
                   from 
                     groups g $map_table
                   where 
                     $where_clause
                   order by 
                     name
      </querytext>
</fullquery>

<fullquery name="cm::modules::install::create_modules.create_module">      
      <querytext>
        begin
	:1 := content_module.new (
	:module_name, --name
	to_lower(:module),
	:root_key,
	:sort_key,
	:package_id, -- parent_id
	:package_id -- package_id
	);
        end;
      </querytext>
</fullquery>

<fullquery name="cm::modules::install::delete_modules.delete_module">      
      <querytext>
	begin
        :1 := content_module.delete (:module_id);
        end;
      </querytext>
</fullquery>
 
</queryset>
