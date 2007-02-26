ad_page_contract {
    List the contents of a folder under in the template repository
    Either a path or a folder ID may be passed to the page.

    @author Michael Steigman
    @creation-date October 2004
} {
    { item_id:integer ""}
    { revision_id:integer,optional }
    { path:optional "" }
    { mount_point "templates"}
    { tab:optional "revisions"}
}
set template_id $item_id
set user_id [auth::require_login]

permission::require_permission -party_id $user_id \
    -object_id $template_id -privilege read

# the ability to pass in a path is not currently utilized by any CMS pages
if { $path ne "" } {
    set item_id [content::item::get_id -item_path $path]
    if { $item_id eq "" } {
	ad_return_complaint 1 "The requested folder \"$path\" does not exist."
    }
} elseif { $item_id eq "" } {
	set folder_id [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]  
	ad_returnredirect [export_vars -base index {mount_point folder_id}]
	ad_script_abort
}

cms::template::get -template_id $item_id
if { ![info exists revision_id] } {
    set revision_id [content::item::get_latest_revision -item_id $item_id]
}

set page_title "Content Template - $template_info(title)"

set write_p [permission::permission_p -party_id $user_id \
		    -object_id $template_id -privilege write]

# set up links that will appear on all tabs
set return_url [ad_return_url]
set revise_url [export_vars -base template-ae {template_id revision_id mount_point tab return_url}]
set rename_url [export_vars -base ../items/rename {item_id mount_point tab return_url}]
set upload_url [export_vars -base upload {template_id revision_id tab return_url}]
set download_url [export_vars -base download {template_id tab return_url}]

# send over to manage-items-2 to delete
set list_action delete
set folder_id $template_info(parent_id)
set delete_url [export_vars -base ../sitemap/manage-items-2 {item_id mount_point folder_id list_action return_url}]
