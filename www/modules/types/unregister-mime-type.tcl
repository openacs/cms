# /types/unregister-mime-type.tcl
# Unregister a MIME type to a content type


request create
request set_param content_type -datatype keyword
request set_param mime_type -datatype text

set db [template::begin_db_transaction]

template::query module_id onevalue "
  select module_id from cm_modules where key = 'types'
" 

# permissions check - must have cm_write to unregister mime type
content::check_access $module_id cm_write -user_id [User::getID]

template::query unregister_mime_type dml "
  begin
    content_type.unregister_mime_type(
        content_type => :content_type,
        mime_type    => :mime_type
    );
  end;"

template::end_db_transaction
template::release_db_handle

content_method::flush_content_methods_cache $content_type

template::forward "index?id=$content_type"
