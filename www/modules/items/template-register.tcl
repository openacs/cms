ad_page_contract {

    @author Michael Steigman
    @creation-date May 2005
} {
    { item_id:naturalnum }
    { mount_point:optional "sitemap" }
    { tab:optional "templates" }
    { template_id:naturalnum,optional }
    { context:optional }
}

# get templates from the clipboard
set clip [cms::clipboard::parse_cookie]
set templates [cms::clipboard::get_items $clip templates]

set template_root [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]

# if no templates are clipped, send user a message and abort
if { [llength $templates] < 1 } {
    util_user_message -message "There are no templates on the clipboard"
    ad_returnredirect [export_vars -base index {item_id tab mount_point}]
} 

ad_form -name select_template -form {
    {item_id:naturalnum(hidden) 
	{value $item_id}}
}

# set up template options (if any)
if { [llength $templates] > 1 } {
    set options [list]
    foreach template_id $templates {
	set path "/[content::template::get_path -template_id $template_id -root_folder_id $template_root]"
	lappend options [list $path $template_id]
    }
    ad_form -extend -name select_template -form {
	{template_id:naturalnum(radio)
	    {label "Template"}
	    {options $options}}
    }

} else {
    set path "/[content::template::get_path -template_id $templates -root_folder_id $template_root]"
    ad_form -extend -name select_template -form {
	{path:text(inform)
	    {label "Template"}
	    {value $path}}
	{template_id:naturalnum(hidden)
	    {value $templates}}
    }
}


set context_options [db_list_of_lists get_contexts {}]
ad_form -extend -name select_template -form {

    {context:text(select)
	{label "Use Context"}
	{options $context_options}}

} -on_submit {

    if { ![db_string second_template_p {}] } {
	content::item::register_template -item_id $item_id \
	    -template_id $template_id -use_context $context
    } else {
	util_user_message -message "There is already a template registered for $context context"
    }

    ad_returnredirect [export_vars -base index { item_id mount_point tab }]

}
