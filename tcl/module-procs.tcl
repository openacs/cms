######################################################
#
# Procedures to generate and maintain the browser's tree
#
# Each module resides in its own namespace, and implements 
# the following 3 procs:
#
# getChildFolders { id } - returns the child folders of a given
#    folder
# getSortedPaths { name id_list {root_id 0} {eval_code {}}} - sets the name to be a multirow
#  datasource listing all paths in sorted order
#  The datasource must contain 3 columns: item_id, item_path and item_type
#
# The folder data structure is a list of the form
#
# { mount_point name id {} expandable_p symlink_p }
#
#####################################################
 

namespace eval cm {

  namespace eval modules {

    # Get the id of some module, return empty string on failure
    ad_proc get_module_id { module_name } {
      template::query gmi_get_module_id id onevalue "
        select module_id from cm_modules
          where key = :module_name
      " -cache "get_module_name $module_name" -persistent

      return $id
    }

    # Get a list of all the mount points
    ad_proc getMountPoints {} {

      template::query gmp_get_mount_points mount_point_list multilist "
       select 
         key, name, '' as id, 
         '' as children, 't' as expandable, 'f' as symlink,
         0 as update_time
       from cm_modules 
       order by sort_key" 
 
      # Append clipboard
      lappend mount_point_list [folderCreate "clipboard" "Clipboard" "" [list] t f 0]

      return $mount_point_list
    }

    # Generic getCHildFolders procedure for sitemap and templates
    ad_proc getChildFolders { mount_point id } {

      # query for child site nodes
      set module_name [namespace tail [namespace current]]

      template::query gcf_get_child_folders result multilist "
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
	  name"

      return $result
    }

    namespace eval workspace {
     #RBM: FIX ME: This has got to be a hack that was left over in the code!
     ad_proc getRootFolderID {} { return 0 } 

      ad_proc getChildFolders { id } {
        return [list]
      }
    }

    namespace eval templates {

      # Retreive the id of the root folder
      ad_proc getRootFolderID {} {
        if { ![nsv_exists browser_state template_root] } {
          template::query grfi_get_root_id root_id onevalue "
            select content_template.get_root_folder() from dual"
          nsv_set browser_state template_root $root_id
          return $root_id
        } else {
          return [nsv_get browser_state template_root]
        }
      }

      ad_proc getChildFolders { id } {
        if { [string equal $id {}] } {
          set id [getRootFolderID]
        }

        # query for child site nodes
        set module_name [namespace tail [namespace current]]

        return [cm::modules::getChildFolders $module_name $id]
      }

      ad_proc getSortedPaths { name id_list {root_id 0} {eval_code {}}} {
        uplevel "
          cm::modules::sitemap::getSortedPaths $name \{$id_list\} $root_id \{$eval_code\}
        "
      }
    }

    namespace eval workflow {
      ad_proc getRootFolderID {} { return 0 } 

      ad_proc getChildFolders { id } {
        return [list]
      }
    }

    namespace eval sitemap {

      # Retreive the id of the root folder
      ad_proc getRootFolderID {} {
        if { ![nsv_exists browser_state sitemap_root] } {
          template::query gri_get_root_id root_id onevalue "
            select content_item.get_root_folder() from dual"
          nsv_set browser_state sitemap_root $root_id
          return $root_id
        } else {
          return [nsv_get browser_state sitemap_root]
        }
      }

      ad_proc getChildFolders { id } {
        if { [string equal $id {}] } {
          set id [getRootFolderID]
        }

        # query for child site nodes
        set module_name [namespace tail [namespace current]]
        
        return [cm::modules::getChildFolders $module_name $id]
      }

      ad_proc getSortedPaths { name id_list {root_id 0} {eval_code {}}} {

        set sql_id_list "'"
        append sql_id_list [join $id_list "','"]
        append sql_id_list "'"
	#FIX ME
        set sql_query [db_map gsp_get_sorted_paths]
	               "select 
                         item_id, 
                         content_item.get_path(item_id, :sorted_paths_root_id) as item_path,
                         content_type as item_type
                       from 
                         cr_items
                       where
                         item_id in ($sql_id_list)
                       order by item_path"

	upvar sql_query __sql
        upvar sorted_paths_root_id _root_id
        set _root_id $root_id
        uplevel "
          template::query gsp_get_paths  multirow \{$__sql\} -eval \{$eval_code\}
        "
      } 
  
    }
    # end of sitemap namespace

    namespace eval types {

      # Return a multilist representing the types tree,
      # for use in a select widget
      ad_proc getTypesTree { } {

        template::query gtt_get_tree_types result multilist "
          select
            lpad(' ', level, '-') || pretty_name as label,
            object_type as value
          from
            acs_object_types t
          connect by
            supertype = prior object_type
          start with
            object_type = 'content_revision'
        "

        set result [concat [list [list "--" ""]] $result]

        return $result
      }

      ad_proc getRootFolderID {} { return "content_revision" } 

      ad_proc getChildFolders { id } {

        set children [list]

        if { [string equal $id {}] } {
          set id [getRootFolderID]
        }

        # query for message categories
        set module_name [namespace tail [namespace current]]

        template::query gcf_get_child_folders result multilist "select
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
                     t.pretty_name"
	
        return $result
      }
    }
    # end of types namespace

    namespace eval search {
      ad_proc getRootFolderID {} { return 0 } 

      ad_proc getChildFolders { id } {
        return [list]
      }
    }

    namespace eval categories {

      ad_proc getRootFolderID {} { return 0 } 

      ad_proc getChildFolders { id } {

        set children [list]

        if { [string equal $id {}] } {
          set where_clause "k.parent_id is null"
        } else {
          set where_clause "k.parent_id = :id"
	}

        set module_name [namespace tail [namespace current]]

        # query for keyword categories

        template::query gcc_get_child_folders children multilist "
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
                     name"

        return $children
      }

      ad_proc getSortedPaths { name id_list {root_id 0} {eval_code {}}} {

        set sql_id_list "'"
        append sql_id_list [join $id_list "','"]
        append sql_id_list "'"
	# FIX ME
        set sql_query [db_map gsp_get_query] "
          select 
            keyword_id as item_id,
            content_keyword.get_path(keyword_id) as item_path,
            'content_keyword' as item_type
          from
            cr_keywords
          where 
            keyword_id in ($sql_id_list)"

	upvar __sql sql_query
        uplevel "
          template::query $name multirow \{$__sql\} -eval \{$eval_code\}
        "
      }

    }
    # end of categories namespace

    namespace eval users {
     ad_proc getRootFolderID {} { return 0 }  

     ad_proc getChildFolders { id } {
      
        if { [string equal $id {}] } {
          set where_clause "not exists (select 1 from group_component_map m
                                          where m.component_id = g.group_id)"
          set map_table ""
        } else {
          set where_clause "m.group_id = :id and m.component_id = g.group_id"
          set map_table ", group_component_map m"
        }

        set module_name [namespace tail [namespace current]]

        template::query gcf_get_child_folders result multilist "select
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
                     name"
        return $result
      }

      ad_proc getSortedPaths { name id_list {root_id 0} {eval_code {}}} {

        set sql_id_list "'"
        append sql_id_list [join $id_list "','"]
        append sql_id_list "'"
	# FIX ME
        set sql_query [db_map gsp_get_sort_paths] "
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
            item_path"

	upvar __sql sql_query
        uplevel "template::query $name multirow \{$__sql\} -eval \{$eval_code\}"
      }
         
    }

    namespace eval clipboard {

      ad_proc getRootFolderID {} { return 0 } 

      ad_proc getChildFolders { id } {

        # Only the mount point is expandable
        if { ![template::util::is_nil id] } {
          return [list]
        }

        set children [list]
 
        set module_name [namespace tail [namespace current]] 

        template::query gcf_child_folders result multilist "
                     select
                     :module_name as mount_point,
                     name, key, '' as children,
                     'f' as expandable,
                     'f' as symlink,
                     0 as update_type
                   from cm_modules order by sort_key"
        return $result
      }
    }
    # end of clipboard namespace
  }  
  # end of modules namespace
} 
# end of cm namespace



