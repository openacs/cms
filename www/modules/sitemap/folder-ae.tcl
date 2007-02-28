ad_page_contract {
    Add/edit a folder

    @author Michael Steigman
    @creation-date October 2004
} {
    { folder_id:integer,optional }
    { parent_id:integer,optional }
    { mount_point:optional "sitemap" }
    { return_url:optional }
}

if { ![info exists parent_id] } {
    set parent_id [cm::modules::${mount_point}::getRootFolderID [ad_conn subsite_id]]
}

if { [ad_form_new_p -key folder_id] } {
    permission::require_permission -party_id [auth::require_login] \
	-object_id $parent_id -privilege write
    set page_title "Add Folder"
} else {
    permission::require_permission -party_id [auth::require_login] \
	-object_id $folder_id -privilege write
    set page_title "Edit Folder"
}

ad_form -name folder -cancel_url $return_url -export { parent_id mount_point return_url } -form {

    folder_id:key

    {name:text(text) 
	{label "Name"}
	{html { size 30 }}
    	{help_text "Short name containing no special characters"}}

    {label:text(text) 
	{label "Label"}
	{html { size 40 }}
	{help_text "More descriptive label"}}

    {description:text(textarea),optional 
	{html {rows 5 cols 80}} 
	{label "Description"}}

} -edit_request {

    cms::folder::get -folder_id $folder_id
    set name $folder_info(name)
    set label $folder_info(label)
    set description $folder_info(description)

} -new_data {


    if { [catch { set folder_id [content::folder::new -name $name -parent_id $parent_id \
			   -label $label -description $description ] } error ] } {
	# couldn't create the folder
	set folder_id $parent_id
	# give a friendlier message for the most common cause
	if { [regexp "cr_items_unique_name" $error] } {
	    set message "Could not create folder because an item with the same name already exists in this folder."
	} else {
	    set message "Could not create the folder. The error was: $error"
	}
	ad_returnredirect -message $message [export_vars -base ../${mount_point}/index folder_id]
	ad_script_abort
    }
    content::folder::register_content_type -folder_id $folder_id \
	-content_type [ad_decode $mount_point "templates" content_template content_revision] \
	-include_subtypes t
    content::folder::register_content_type -folder_id $folder_id \
	-content_type content_folder -include_subtypes t

} -edit_data {

    set attributes [list [list name "$name"] [list label "$label"] [list description "$description"]]
    content::folder::update -folder_id $folder_id -attributes $attributes

} -after_submit {

    ad_returnredirect [export_vars -base ../${mount_point}/index { mount_point folder_id }]
    ad_script_abort
}
