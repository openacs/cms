request create
request set_param attribute_id -datatype integer

permission::require_permission -party_id [auth::require_login] \
    -object_id [cm::modules::get_module_id -module_name types -subsite_id [ad_conn subsite_id]] -privilege write

db_1row get_attr_info ""

if { [catch { db_exec_plsql unregister {} } errmsg] } {
  template::request::error unregister_attribute_widget $errmsg
}


template::forward index?content_type=$content_type
