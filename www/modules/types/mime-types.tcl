# /types/register-mime-types.tcl
# A form for registering mime types to a content type


request create
request set_param content_type -datatype keyword -value 'content_revision'

permission::require_permission -party_id [auth::require_login] \
    -object_id [cm::modules::get_module_id -module_name types -subsite_id [ad_conn subsite_id]] -privilege read

set content_type_name [db_string get_name ""]

set unregistered_mime_types [db_list_of_lists get_unreg_mime_types ""]

set unregistered_mime_types_count [llength $unregistered_mime_types]

if { [template::util::is_nil content_type_name] } {
    ns_log Notice \
      "register-mime-types.tcl - ERROR:  BAD CONTENT_TYPE - $content_type"
    template::forward "index?content_type=content_revision"
}

template::list::create \
    -name mime_types \
    -multirow registered_mime_types \
    -key mime_type \
    -bulk_actions [list "Unregister marked mime types" \
                       [export_vars -base unregister-mime-type {mount_point}] \
                       "Unregister marked mime types"] \
    -bulk_action_export_vars content_type \
    -no_data "No mime types registered to this content type yet." \
    -elements {
	label {
	    label "Mime Type"
	}
    }

db_multirow registered_mime_types get_reg_mime_types {}

set page_title "Register MIME types to $content_type_name"


form create register -action mime-types

element create register id \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create register content_type \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create register mime_type \
	-datatype text \
	-widget select \
	-label "Register MIME Types" \
	-options $unregistered_mime_types



if { [form is_valid register] } {
    form get_values register content_type mime_type
    ns_log notice "========================================== is_valid! "
    content::type::register_mime_type -content_type $content_type \
	-mime_type $mime_type

    cms::type::flush_content_methods_cache $content_type
    set type_props_tab mime_types
    ad_returnredirect [export_vars -base index {content_type type_props_tab}]
}
