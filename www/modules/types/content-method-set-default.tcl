# /cms/www/modules/types/content-method-set-default.tcl
#
# Set the default content insertion method for a content type


request create
request set_param content_type   -datatype keyword
request set_param content_method -datatype keyword
request set_param return_url     -datatype text -value ""

# default return_url
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type"
}


set db [template::begin_db_transaction]

template::query set_content_method_default dml "
  begin
  content_method.set_default_method (
      content_type   => :content_type,
      content_method => :content_method
  );
  end;
"

template::end_db_transaction
template::release_db_handle

content_method::flush_content_methods_cache $content_type

template::forward $return_url