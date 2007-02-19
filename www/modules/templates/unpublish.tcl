ad_page_contract {

    @author Michael Steigman
    @creation-date October 2004
} {
    { item_id:naturalnum }
    { mount_point "templates" }
    { tab:optional "revisions" }
}

# remove the template from the file system and unset live
set path "/templates/"
append path [content::template::get_path -template_id $item_id -root_folder_id "-100"]

if { [ catch {
    ns_unlink [acs_root_dir]$path.adp
    content::item::unset_live_revision -item_id $item_id } err ] } {
    util_user_message -message "There was an error removing the file and/or unsetting the live revision: $err"
} else {
    util_user_message -message "Template was deleted from file system and publish status of \"live\" was removed"
}

ad_returnredirect [export_vars -base properties {item_id tab mount_point}]
ad_script_abort
