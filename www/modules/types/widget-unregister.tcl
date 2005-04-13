request create
request set_param attribute_id -datatype integer

set module_id [db_string get_module_id ""]
permission::require_permission -party_id [auth::require_login] \
    -object_id $module_id -privilege write

db_1row get_attr_info ""

if { [catch { db_exec_plsql unregister {} } errmsg] } {
  template::request::error unregister_attribute_widget $errmsg
}


template::forward index?id=$content_type
