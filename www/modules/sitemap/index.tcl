ad_page_contract {
    List contents of a folder
    List path of this folder
    List path of any symlinks to this folder


    @author Michael Steigman
    @creation-date October 2004
} {
    { item_id:integer ""}
    { mount_point "sitemap" }
    { parent_id:integer ""}
    { orderby "name" }
}

# request create
# request set_param id -datatype keyword -optional
# request set_param mount_point -datatype keyword -optional -value sitemap
# request set_param parent_id -datatype keyword -optional
# request set_param orderby -datatype keyword -optional -value name

# paginator variables
#request set_param page -datatype integer -value 1

# Create all the neccessary URL params for passthrough
set passthrough "mount_point=$mount_point&parent_id=$parent_id"

set original_id $item_id
set user_id [auth::require_login]
set root_id [cm::modules::${mount_point}::getRootFolderID]

set package_url [ad_conn package_url]

# Get the folder label/description
#   If :id does not exist, then use :root_id
if { [template::util::is_nil item_id] } {

  set parent_var :root_id

  set module_name [db_string get_module_name ""]

  set info(label) $module_name
  set info(description) ""
  set what "Folder"
  set is_symlink f

  # get all the content types registered to this folder
  # check whether this folder allows subfolders, symlinks, and templates
  set registered_types [db_list get_reg_types ""]

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

  set parent_var :item_id

  # Resolve the symlink, if any
  set resolved_id [db_string get_resolved_id ""]

  if { $resolved_id != $item_id } {
    set is_symlink t
    set item_id $resolved_id
    set what "Link"
  } else {
    set is_symlink f
    set what "Folder"
  }

  db_1row get_info "" -column_array info

  # Determine the parent id if none exists
  set parent_id $info(parent_id)
  if { [template::util::is_nil parent_id] } {
      set parent_id ""
  }


  # get all the content types registered to this folder
  # check whether this folder allows subfolders, symlinks, and templates
  set registered_types [db_list get_types ""]

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

set page_title "Content Folder - $info(label)"

# Make sure the user has the right access to this folder,
# set up the user_permissions array
if { [template::util::is_nil item_id] } {
  set object_id $root_id
} else {
  set object_id $item_id
}  

content::check_access $object_id "cm_examine" \
  -user_id $user_id -mount_point $mount_point -parent_id $parent_id \
  -return_url "modules/sitemap/index" \
  -passthrough [list [list item_id $original_id] [list orderby $orderby]]


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

set index_page_id [db_string get_index_page_id ""]

# REMOVED CODE GOES HERE

# symlinks to this folder/item
db_multirow symlinks get_symlinks ""

# build folder contents list

if { [template::util::is_nil item_id] } {
    set folder_id $root_id
    set parent_id $root_id
} else {
    set folder_id $item_id
    set parent_id $item_id
}  

template::list::create \
    -name folder_items \
    -multirow folder_contents \
    -has_checkboxes \
    -key item_id \
    -actions [list "Attributes" [export_vars -base attributes?mount_point=sitemap {folder_id}] "Folder Attributes" \
		  "Delete Folder" [export_vars -base delete?mount_point=sitemap {item_id}] "Delete this folder" \
		  "Rename Folder" [export_vars -base rename?mount_point=sitemap {item_id}] "Rename this folder" \
		  "New Folder" [export_vars -base create?mount_point=sitemap {parent_id}] "Create a new folder within this folder" \
		  "Move Items" [export_vars -base move?mount_point=sitemap {item_id}] "Move marked items to this folder" \
		  "Copy Items" [export_vars -base copy?mount_point=sitemap {item_id}] "Copy marked items to this folder" \
		  "Link Items" [export_vars -base symlink?mount_point=sitemap {item_id}] "Link marked items to this folder" \
		  "Delete Items" [export_vars -base delete-items?mount_point=sitemap {item_id}] "Delete marked items"] \
    -elements {
	copy {
	    label "Clipboard"
	    display_template "<center>@folder_contents.copy;noquote@</center>"
	}
	title {
	    label "Name"
	    link_html { title "View this item"}
	    link_url_col item_url
	}
	file_size {
	    label "Size"
	}
	publish_date {
	    label "Publish Date"
	}
	content_type {
	    label "Type"
	}
	last_modified_date {
	    label "Last Modified"
	}
    }

db_multirow -extend { item_url copy } folder_contents get_folder_contents "" {
    if { $is_folder } {
	set item_url [export_vars -base index?mount_point=sitemap { item_id parent_id }]
    } else {
	set item_url [export_vars -base ../items/index?mount_point=sitemap { item_id revision_id parent_id }]
    }
    set copy [clipboard::render_bookmark sitemap $item_id $package_url]
}

form create add_item

if { [template::util::is_nil original_id] } {
    set the_id $root_id
} else {
    set the_id $original_id
}

element create add_item item_id \
	-datatype integer -widget hidden -param -optional

element create add_item mount_point \
	-datatype string -widget hidden -param -optional

set revision_types [cms_folder::get_registered_types $the_id]
set num_revision_types [llength $revision_types]

element create add_item content_type \
	-datatype keyword \
	-widget select \
	-label "Content Type" \
	-options $revision_types

if { [form is_valid add_item] } {
    form get_values add_item item_id mount_point content_type

    # if the folder_id is empty, then it must be the root folder
    if { [template::util::is_nil item_id] } {
	set folder_id [cm::modules::${mount_point}::getRootFolderID]
    } else {
	set folder_id $item_id
    }

    if { [string equal $mount_point "templates"] } {
	forward "../items/template?parent_id=$folder_id&mount_point=$mount_point"
    } else {
 	forward "../items/create-1?parent_id=$folder_id&mount_point=$mount_point&content_type=$content_type"
    }
}



