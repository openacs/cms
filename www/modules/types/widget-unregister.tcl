request create
request set_param attribute_id -datatype integer


# permissions check - must have cm_write on the types module to unregister
#  a widget
template::query get_module_id module_id onevalue "
  select
    module_id
  from
    cm_modules
  where
    key = 'types'
"

content::check_access $module_id cm_write -user_id [User::getID]


template::query get_attr_info attribute_info onerow "
  select
    attribute_name, object_type as content_type
  from
    acs_attributes
  where
    attribute_id = :attribute_id
" 

template::util::array_to_vars attribute_info


if { [catch {db_exec_plsql unregister "
  begin
  cm_form_widget.unregister_attribute_widget (
      content_type   => :content_type,
      attribute_name => :attribute_name
  );
  end;
"} errmsg] } {
  template::request::error unregister_attribute_widget $errmsg
}


template::forward index?id=$content_type
