# /types/unregister-mime-type.tcl
# Unregister a MIME type to a content type


request create
request set_param content_type -datatype keyword
request set_param mime_type -datatype text


db_transaction {

    permission::require_permission -party_id [auth::require_login] \
	-object_id [cm::modules::get_module_id -module_name types -subsite_id [ad_conn subsite_id]] -privilege write

    db_exec_plsql unregister_mime_type {}

}

content_method::flush_content_methods_cache $content_type

template::forward "index?content_type=$content_type"
