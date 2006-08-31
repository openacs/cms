ad_page_contract {

    @author Michael Steigman
    @creation-date October 2004
} {
    { template_id:integer,optional }
    { folder_id:integer,optional "" }
    { revision_id:integer,optional ""}
    { return_url:optional }
}


set user_id [auth::require_login]
if { [ad_form_new_p -key template_id] } {
    permission::require_permission -party_id $user_id \
	-object_id $folder_id -privilege create
    set page_title "Add Template"
} else {
    permission::require_permission -party_id $user_id \
	-object_id $template_id -privilege write
    set page_title "Edit Template"
}

ad_form -name template -cancel_url $return_url -export { return_url folder_id } -form {
    template_id:key
}

# can't rename a template here
if { [ad_form_new_p -key template_id] } {
    ad_form -extend -name template -form {
	{name:text(text) 
	    {label "Template Name"}
	    {help_text "Short name containing no special characters or space"}
	}
    }
} else {
    ad_form -extend -name template -form {
	{name:text(inform) 
	    {label "Template Name"}
	    {help_text "Use the rename button to change the template name"}
	}
    }
}

ad_form -extend -name template -form {
    
    {title:text(text) 
	{label "Title"}
	{help_text "Short descriptive title"}}

    {description:text(textarea),optional 
	{html {rows 5 cols 80}} 
	{label "Description"}
	{help_text "Description of template"}}

    {mime_type:text(select)
	{label "Mime Type"}
	{options [cms::template::mime_type_options]}}

    {content:text(richtext),optional 
	{html {rows 20 cols 80}} 
	{label "Template Content"}}

} -edit_request {

    if { ![ad_form_new_p -key template_id] } {
	cms::template::get -template_id $template_id -revision_id $revision_id -array_name one_revision
	set template_id $one_revision(item_id)
	set name $one_revision(name)
	set title $one_revision(title)
	set description $one_revision(description)
	set content [template::util::richtext::create $one_revision(content) {}]
	set mime_type $one_revision(mime_type)
    }

} -edit_data {
    
    db_transaction {
	cms::template::add_revision -template_id $template_id -title $title \
	    -description $description -content $content -mime_type $mime_type \
	    -creation_user [ad_conn user_id] -creation_ip [ad_conn peeraddr]
    }

} -new_data {

    # create the template and revision
    db_transaction {    
	set template_id [content::template::new -name $name -parent_id $folder_id]
	cms::template::add_revision -template_id $template_id -title $title \
	    -description $description -content $content -mime_type $mime_type \
	    -creation_user [ad_conn user_id] -creation_ip [ad_conn peeraddr]
    }

} -after_submit {

    if { [info exists return_url] } {
	ad_returnredirect $return_url
    } else {
	set item_id $template_id
	ad_returnredirect [export_vars -base properties { item_id }]
    }
    ad_script_abort

}
