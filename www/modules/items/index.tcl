ad_page_contract {
    Assemble information for a content item.  Note this page is only
    appropriate for revisioned content items.  Non-revisioned content
    items (symlinks, extlinks and folders) have separate admin pages

    @author Michael Steigman
    @creation-date May 2005
} {
    { item_id:integer }
    { revision_id:integer,optional }
    { mount_point:optional "sitemap" }
    { tab:optional "item" }
}

set package_url [ad_conn package_url]

# HACK: sometimes the query string does not get parsed when returning
# from revision-add-2.  The reason for this is unclear.
# if { [string equal [ns_queryget item_id] {}] } {
#   ns_log Notice "ITEM ID NOT FOUND...PARSING QUERY STRING"
#   set item_id [lindex [split [ns_conn query] "="] 1]
# }

# resolve any symlinks
set item_id [content::symlink::resolve -item_id $item_id]

set user_id [auth::require_login]
permission::require_permission -party_id $user_id \
    -object_id $item_id -privilege read

set write_p [permission::permission_p -party_id $user_id \
		    -object_id $item_id -privilege write]

content::item::get -item_id $item_id -revision latest
if { ![info exists revision_id] } {
    set revision_id $content_item(latest_revision)
}

#db_1row get_info "" -column_array info
#template::util::array_to_vars info

set page_title "Content Item - $content_item(title)"

# build the path to the custom interface directory for this content type

set custom_dir [file dirname [ns_conn url]]/custom/$content_item(content_type)

# check for the custom info page and redirect if found

if { [file exists [ns_url2file $custom_dir/index.tcl]] } {

  template::forward $custom_dir/index?item_id=$item_id
}

if { [cms::item::storage_type -revision_id $revision_id] eq "text" } {
    set revise_button "Author Revision"
    if { [cms::item::has_text_content_p -revision_id $revision_id] } {
	set content_method text_entry
    } else {
	set content_method no_content
    }
} else {
    set revise_button "Upload Revision"
    set content_method file_upload
}

set return_url [ad_return_url]
set revise_url [export_vars -base revision-add-2 {item_id revision_id mount_point tab content_method return_url}]
set rename_url [export_vars -base rename {item_id mount_point tab return_url}]
set content_root [cm::modules::sitemap::getRootFolderID [ad_conn subsite_id]]
set preview_url "[subsite::get_element -subsite_id [ad_conn subsite_id] -element url -notrailing]/[content::item::get_path -root_folder_id $content_root -item_id $item_id]"

# send over to manage-items-2 to delete
set action delete
set folder_id $content_item(parent_id)
set delete_url [export_vars -base ../sitemap/manage-items-2 {item_id mount_point folder_id action return_url}]

