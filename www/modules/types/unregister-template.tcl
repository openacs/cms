# modules/types/unregister-template.tcl
#  unregisters a template

request create
request set_param template_id -datatype integer
request set_param context -datatype keyword
request set_param content_type -datatype keyword
request set_param type_props_tab -datatype text -optional -value templates
request set_param mount_point -datatype text -optional -value types

content::type::unregister_template -content_type $content_type \
    -template_id $template_id -use_context $context

ad_returnredirect [export_vars -base index {content_type mount_point type_props_tab}]
