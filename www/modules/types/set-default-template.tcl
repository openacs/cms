# /cms/www/modules/types/set-default-template.tcl
# Sets a template registered to a content type/context to be the default


request create
request set_param template_id  -datatype integer
request set_param context      -datatype keyword
request set_param content_type -datatype keyword
request set_param return_url   -datatype text     -optional


set db [template::begin_db_transaction]


# set the default template, automatically unsetting any preexisting default
template::query set_default_template dml "
  begin
  content_type.set_default_template(
      template_id  => :template_id,
      content_type => :content_type,
      use_context  => :context );
  end;"

template::end_db_transaction
template::release_db_handle

# set the default return_url if none exists
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type&mount_point=types"
}

forward $return_url
