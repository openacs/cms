# List contents of a folder
# List path of this folder
# List path of any symlinks to this folder

request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param parent_id -datatype keyword -optional
request set_param orderby -datatype keyword -optional -value name


# paginator variables
request set_param page -datatype integer -value 1

# Create all the neccessary URL params for passthrough
set passthrough "mount_point=$mount_point&parent_id=$parent_id"

set original_id $id
set user_id [User::getID]
set root_id [cm::modules::${mount_point}::getRootFolderID]


# Get the folder label/description
#   If :id does not exist, then use :root_id
if { [template::util::is_nil id] } {

  set parent_var :root_id

  template::query get_module_name module_name onevalue "
    select name from cm_modules where key = :mount_point
  " 

  set info(label) $module_name
  set info(description) ""
  set what "Folder"
  set is_symlink f

  # get all the content types registered to this folder
  # check whether this folder allows subfolders, symlinks, and templates
  template::query get_reg_types registered_types onelist "
    select
      content_type
    from
      cr_folder_type_map
    where
      folder_id = :root_id
  " 

  set subfolders_allowed f
  set symlinks_allowed f
  set templates_allowed f
  if { [lsearch -exact $registered_types "content_folder"] != -1 } {
    set subfolders_allowed t
  }
  if { [lsearch -exact $registered_types "content_symlink"] != -1 } {
    set symlinks_allowed t
  }
  if { [lsearch -exact $registered_types "content_template"] != -1 } {
    set templates_allowed t
  }

  set parent_id ""

} else {

  set parent_var :id

  # Resolve the symlink, if any
  template::query get_resolved_id resolved_id onevalue "
    select content_symlink.resolve( :id ) from dual
  "

  if { $resolved_id != $id } {
    set is_symlink t
    set id $resolved_id
    set what "Link"
  } else {
    set is_symlink f
    set what "Folder"
  }

  template::query get_info info onerow "
    select
      parent_id, NVL(label, name) label, description
    from
      cr_items i, cr_folders f
    where
      i.item_id = f.folder_id
    and
      f.folder_id = :id
  " 

  # Determine the parent id if none exists
  set parent_id $info(parent_id)
  if { [template::util::is_nil parent_id] } {
      set parent_id ""
  }


  # get all the content types registered to this folder
  # check whether this folder allows subfolders, symlinks, and templates
  template::query get_types registered_types onelist "
    select
      content_type
    from
      cr_folder_type_map
    where
      folder_id = :id
  " 

  set subfolders_allowed f
  set symlinks_allowed f
  set templates_allowed f
  if { [lsearch -exact $registered_types "content_folder"] != -1 } {
    set subfolders_allowed t
  }
  if { [lsearch -exact $registered_types "content_symlink"] != -1 } {
    set symlinks_allowed t
  }
  if { [lsearch -exact $registered_types "content_template"] != -1 } {
    set templates_allowed t
  }


}


# Make sure the user has the right access to this folder,
# set up the user_permissions array
if { [template::util::is_nil id] } {
  set object_id $root_id
} else {
  set object_id $id
}  

content::check_access $object_id "cm_examine" \
  -user_id $user_id -mount_point $mount_point -parent_id $parent_id \
  -return_url "modules/sitemap/index" \
  -passthrough [list [list id $original_id] [list orderby $orderby]]


# If the user doesn't have the New permission, he can't create any new items
# at all
if { [string equal $user_permissions(cm_new) f] } {
  set info(subfolders_allowed) f
  set info(symlinks_allowed) f
  set info(templates_allowed) f
}




# Get the cookie; prepare for setting bookmarks
#set clip [clipboard::parse_cookie]

# Get the index page ID

template::query get_index_page_id index_page_id onevalue "
  select content_folder.get_index_page($parent_var) from dual
"


set id_sql "
  select
    r.item_id, '' as context,
    decode(o.object_type, 'content_symlink', r.label,
			  'content_folder', f.label,
			  nvl(v.title, i.name)) title,
    decode(r.item_id, :index_page_id, 't', 'f') is_index_page,
    nvl(to_char(round(dbms_lob.getlength(v.content) / 1000, 1)), '-') file_size
  from 
    cr_resolved_items r, cr_items i, cr_folders f, cr_revisions v, 
    cr_revisions u, acs_objects o, acs_object_types t
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
  and
    i.latest_revision = v.revision_id (+)
  and
    i.live_revision = u.revision_id (+)
  and
    i.item_id = f.folder_id (+)
  order by
    is_index_page desc "

# sort table by columns
switch -exact -- $orderby {
  size  {
    set orderby_clause ", o.object_type, file_size desc"
  } 
  publish_date {
    set orderby_clause ", o.object_type, publish_date desc"
  } 
  last_modified {
    set orderby_clause ", o.object_type, last_modified desc"
  }
  object_type {
    set orderby_clause ", o.object_type, content_type, upper(title)"
  }  
  default {
    set orderby_clause ", o.object_type, upper(title)"
  }
}


append id_sql $orderby_clause




set display_sql "
  select
    decode(i.content_type, 'content_folder', 't', 'f') is_folder,
    decode(i.content_type, 'content_template', 't', 'f') is_template,
    r.item_id, r.resolved_id, r.is_symlink, r.name,
    NVL(trim(
      decode(o.object_type, 'content_symlink', r.label,
			  'content_folder', f.label,
			  nvl(v.title, i.name))),
      '-') title,
    decode(i.publish_status, 'live', 
      to_char(u.publish_date, 'MM/DD/YYYY'), '-') publish_date,
    o.object_type, t.pretty_name content_type,
    to_char(o.last_modified, 'MM/DD/YYYY HH24:MI') last_modified_date,
    decode(r.item_id, :index_page_id, 't', 'f') is_index_page,
    nvl(to_char(round(dbms_lob.getlength(v.content) / 1000, 1)), '-') file_size
  from 
    cr_resolved_items r, cr_items i, cr_folders f, cr_revisions v, 
    cr_revisions u, acs_objects o, acs_object_types t
  where
    r.parent_id = $parent_var
  and
    r.resolved_id = i.item_id
  and
    i.item_id = o.object_id
  and
    i.content_type = t.object_type
  and
    i.latest_revision = v.revision_id (+)
  and
    i.live_revision = u.revision_id (+)
  and
    i.item_id = f.folder_id (+)
  and
    -- paginator sql
    r.item_id in (CURRENT_PAGE_SET)
  order by
    is_index_page desc $orderby_clause"



# paginator
set p_name "folder_contents_${mount_point}_$id"
paginator create $p_name $id_sql -pagesize 10 -groupsize 10 -contextual

paginator get_data $p_name items $display_sql item_id $page
paginator get_display_info $p_name info $page

set group [paginator get_group $p_name $page]

paginator get_context $p_name pages [paginator get_pages $p_name $group]
paginator get_context $p_name groups [paginator get_groups $p_name $group 10]


# determine whether item is marked (on clipboard), its link and icon
for { set i 1 } { $i <= [multirow size items] } { incr i } { 
  multirow get items $i

  # use the appropriate icon depending on whether 
  # the icon is bookmarked or not
  #clipboard::get_bookmark_icon $clip $mount_point $items(item_id) items

  # Create a link based on object type
  if { [string equal $items(is_folder) t] } {
    if { [string equal $items(is_symlink) t] } {
      set base_url "index?id=$items(item_id)"
    } else {
      set base_url "index?id=$items(resolved_id)"
    }
  } else {
    set base_url \
	    "../items/index?item_id=$items(resolved_id)"
  }
  set items(link) "${base_url}&mount_point=$mount_point&parent_id=$id"

  # Specify an item based on object type
  if { [string equal $items(is_symlink) t] } {
    set items(icon) "Shortcut24"
  } elseif { [string equal $items(is_folder) t] } {
    set items(icon) "Open24"
  } elseif { [string equal $items(is_template) t] } {
    set items(icon) "generic-item"
  } else {
    set items(icon) "Page24"
  }

  # Set the correct name if the object is a template
  # Change this to actually do the right thing !
  if { [string equal $items(is_template) t] } {
    set items(title) $items(name)
  } 
}



# symlinks to this folder/item
template::query get_symlinks symlinks multirow "
  select
    i.item_id id,
    content_item.get_path(i.item_id) path
  from 
    cr_items i, cr_symlinks s
  where
    i.item_id = s.target_id
  and
    i.item_id = :original_id
"


form create add_item

if { [template::util::is_nil id] } {
    set the_id $root_id
} else {
    set the_id $id
}

element create add_item id \
	-datatype keyword -widget hidden -param -optional

element create add_item mount_point \
	-datatype keyword -widget hidden -param -optional

set revision_types [cms_folder::get_registered_types $the_id]
set num_revision_types [llength $revision_types]

element create add_item content_type \
	-datatype keyword \
	-widget select \
	-label "Content Type" \
	-options $revision_types

if { [form is_valid add_item] } {
    form get_values add_item id mount_point content_type

    # if the folder_id is empty, then it must be the root folder
    if { [template::util::is_nil id] } {
	set folder_id [cm::modules::${mount_point}::getRootFolderID]
    } else {
	set folder_id $id
    }

    if { [string equal $mount_point "templates"] } {
	forward "../items/template?parent_id=$folder_id&mount_point=$mount_point"
    } else {
 	forward "../items/create-1?parent_id=$folder_id&mount_point=$mount_point&content_type=$content_type"
    }
}



