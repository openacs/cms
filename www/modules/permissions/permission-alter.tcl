request create
request set_param object_id -datatype integer 
request set_param grantee_id -datatype integer
request set_param return_url -datatype text -optional
request set_param passthrough -datatype text -optional
request set_param ext_passthrough -datatype text -optional -value $passthrough

set user_id [User::getID]

set db [template::get_db_handle]

template::query info onerow "
  select 
    acs_object.name(:object_id) as object_name, 
    acs_object.name(:grantee_id) as grantee_name,
    acs_permission.permission_p(:object_id, :user_id, 'cm_perm') as user_cm_perm
  from
    dual"

if { [string equal $info(user_cm_perm) t] } {

  form create own_permissions 
  content::perm_form_generate own_permissions \
   { ext_passthrough return_url } 
  content::perm_form_process own_permissions 

  if { [form is_valid own_permissions] && ![util::is_nil return_url] } {
    template::query::flush_cache "content::check_access ${grantee_id}*"
    template::release_db_handle
    template::forward "$return_url?[content::url_passthrough $ext_passthrough]"
  }
}

template::release_db_handle