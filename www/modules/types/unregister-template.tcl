# modules/types/unregister-template.tcl
#  unregisters a template


request create
request set_param template_id -datatype integer
request set_param context -datatype keyword
request set_param content_type -datatype keyword


set db [template::begin_db_transaction]

template::query unregister_template dml "
  begin
    content_type.unregister_template(
      template_id  => :template_id,
      content_type => :content_type,
      use_context  => :context );
  end;"

template::end_db_transaction
template::release_db_handle

template::forward "../types/index?id=$content_type&mount_point=types"
