# /cms/www/modules/types/content-method-unregister.tcl
#
# Unregister a content method from a content type


request create
request set_param content_type   -datatype keyword
request set_param content_method -datatype keyword
request set_param return_url     -datatype text -value ""

# default return_url
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type"
}


set db [template::begin_db_transaction]

template::query content_method_unregister dml "
  begin
  content_method.remove_method (
      content_type   => :content_type,
      content_method => :content_method
  );
  end;
"

template::end_db_transaction
template::release_db_handle


template::forward $return_url