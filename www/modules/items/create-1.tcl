ad_page_contract {

    create-1.tcl
    choose content method from (no content, file upload, text entry, xml import)
    then forward to create-2 or revision-upload

} {
    { content_type:optional "content_revision" }
    { mount_point:optional "sitemap" }
    { parent_id:optional "" }
    { return_url:optional "" }
}

# Manually set the value since the templating system is still broken in 
# the -value flag
if { $parent_id eq "" } {
    set parent_id [cm::modules::${mount_point}::getRootFolderID [ad_conn subsite_id]]
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $parent_id -privilege write

# check for custom create-1 form
if { [file exists [ns_url2file \
	"custom/$content_type/create-1.tcl"]] } {

    template::forward "custom/$content_type/create-1?content_type=$content_type&mount_point=$mount_point&parent_id=$parent_id"
}


set content_type_name [cms::type::pretty_name -content_type $content_type]
set page_title "Create a New $content_type_name"

if { $content_type_name eq "" } {
    template::request::error bad_content_type \
	    "create-1.tcl - Bad content type - $content_type"
}


# get the list of associated content methods
set content_methods [cms::type::get_content_methods $content_type -get_labels]
set first_method [lindex [lindex $content_methods 0] 1]
set first_label  [lindex [lindex $content_methods 0] 0]

form create choose_content_method -cancel_url $return_url

element create choose_content_method parent_id \
    -datatype integer \
    -widget hidden \
    -value $parent_id

element create choose_content_method content_type \
    -datatype keyword \
    -widget hidden \
    -value $content_type

element create choose_content_method return_url \
    -datatype text \
    -widget hidden \
    -value $return_url \
    -optional

# if there is only one valid content_method, don't show the radio buttons
#    and instead use a hidden widget and inform widget for content_method
if { [llength $content_methods] == 1 } {

    element create choose_content_method content_method \
	    -datatype keyword \
	    -widget hidden \
	    -value $first_method

    element create choose_content_method content_method_inform \
	    -widget inform \
	    -label "Content Method" \
	    -value $first_label
} else {

    element create choose_content_method content_method \
	    -datatype keyword \
	    -widget radio \
	    -label "Content Method" \
	    -options $content_methods \
	-help_text "Choose a method for entering this item's content" \
	    -values $first_method
}


# Add the relation tag element
cms::form::add_child_relation_element choose_content_method -section

# if there is no relation tag necessary and there is only one content method,
#    then forward to create-2 with that content method
if { ![element exists choose_content_method relation_tag] && \
	[llength $content_methods] == 1 } {
    set content_method $first_method
    ad_returnredirect [export_vars -base create-2 {parent_id content_type content_method return_url}]
    ad_script_abort
}

# Process the form
if { [form is_valid choose_content_method] } {

    form get_values choose_content_method \
	    content_type parent_id content_method

    if { [element exists choose_content_method relation_tag] } {
	set relation_tag \
		[element get_value choose_content_method relation_tag]
    }
    if { [util::is_nil relation_tag] } {
	set relation_tag ""
    }



    # XML imports should forward to revision-upload
    # otherwise pass the content_method to revision-add
    if { [string equal $content_method "xml_import"] } {
	ad_returnredirect [export_vars -base revision-upload {content_type parent_id relation_tag}]
	ad_script_abort
    }

    ad_returnredirect [export_vars -base create-2 {content_type parent_id content_method relation_tag return_url}]
    ad_script_abort
}



