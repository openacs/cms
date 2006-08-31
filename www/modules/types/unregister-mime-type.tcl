ad_page_contract {
    Unregister a MIME type to a content type

    @author Michael Steigman
    @creation-date April 2006
} {
    { mime_type:multiple }
    { content_type }
    { type_props_tab "mime_types" }
}

permission::require_permission -party_id [auth::require_login] \
    -object_id [cm::modules::get_module_id -module_name types \
		    -subsite_id [ad_conn subsite_id]] -privilege write

foreach mt $mime_type {
    content::type::unregister_mime_type -content_type $content_type \
	-mime_type $mt
}

cms::type::flush_content_methods_cache $content_type
ad_returnredirect [export_vars -base index {content_type type_props_tab}]
