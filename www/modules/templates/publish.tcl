ad_page_contract {

    @author Michael Steigman
    @creation-date October 2004
} {
    { revision_id:integer}
    { return_url }
}

set template_id [cms::item::get_id_from_revision -revision_id $revision_id]

# write the template to the file system
set text [content::get_content_value $revision_id]
set path "/templates/"
append path [content::template::get_path -template_id $template_id -root_folder_id "-100"]

if { [ catch {
    util::write_file [acs_root_dir]$path.adp $text
    content::item::set_live_revision -revision_id $revision_id } err ] } {
    util_user_message -message "There was an error writing the file and/or setting the live revision: $err"
} else {
    util_user_message -message "[content::revision::revision_name -revision_id $revision_id] written to file system and marked \"live\""
}

ad_returnredirect $return_url
ad_script_abort

