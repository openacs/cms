# /cms/modules/items/index.tcl

# Assemble information for a content item.  Note this page is only
# appropriate for revisioned content items.  Non-revisioned content
# items (symlinks, extlinks and folders) have separate admin pages

# Most information on this page is included via components.

# HACK: sometimes the query string does not get parsed when returning
# from revision-add-2.  The reason for this is unclear.

set package_url [ad_conn package_url]

if { [string equal [ns_queryget item_id] {}] } {
  ns_log Notice "ITEM ID NOT FOUND...PARSING QUERY STRING"
  set item_id [lindex [split [ns_conn query] "="] 1]
}

# The mount_point is used to determine the proper root context
# when querying the path to the item.

request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param item_props_tab -datatype keyword -optional -value editing
request set_param page -datatype integer -optional -value 1 


# resolve any symlinks
set resolved_item_id [db_string get_item_id ""]

set item_id $resolved_item_id

set user_id [auth::require_login]
permission::require_permission -party_id $user_id \
    -object_id $item_id -privilege read

set can_edit_p [permission::permission_p -party_id $user_id \
		    -object_id $item_id -privilege write]

# query the content_type of the item ID so we can check for a custom info page
db_1row get_info "" -column_array info
template::util::array_to_vars info

set item_title [db_string get_item_title ""]
set page_title "Content Item - $item_title"

# build the path to the custom interface directory for this content type

set custom_dir [file dirname [ns_conn url]]/custom/$content_type

# check for the custom info page and redirect if found

if { [file exists [ns_url2file $custom_dir/index.tcl]] } {

  template::forward $custom_dir/index?item_id=$item_id
}

# The root ID is to determine the appropriate path to the item

if { [string equal $mount_point templates] } {
    set root_id [cm::modules::templates::getRootFolderID]
} else {
    set root_id [cm::modules::sitemap::getRootFolderID]
} 

# Set up passthrough for permissions
set return_url [ns_conn url]
set passthrough [content::assemble_passthrough \
  return_url mount_point item_id]

### Create the tab strip for showing individual item property pages

# Get the current tab, if any


set url [ad_conn url]
append url "?item_id=$item_id&mount_point=$mount_point&page=$page"

# template::tabstrip create item_props -base_url $url
# template::tabstrip add_tab item_props editing "Editing" editing
# template::tabstrip add_tab item_props children "Sub-Items" children
# template::tabstrip add_tab item_props publishing "Publishing" publishing
# template::tabstrip add_tab item_props permissions "Permissions" permissions
