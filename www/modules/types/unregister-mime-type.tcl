# /types/unregister-mime-type.tcl
# Unregister a MIME type to a content type


request create
request set_param content_type -datatype keyword
request set_param mime_type -datatype text


db_transaction {

    set module_id [db_string get_module_id ""]
    permission::require_permission -party_id [auth::require_login] \
	-object_id $module_id -privilege write

    db_exec_plsql unregister_mime_type {}

}

content_method::flush_content_methods_cache $content_type

template::forward "index?id=$content_type"
