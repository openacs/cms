# Delete a content symlink

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional

set db [template::begin_db_transaction]
template::query symlink_delete dml "
  begin content_symlink.delete(:id); end;
" 
template::end_db_transaction
template::release_db_handle

template::forward "../../sitemap/refresh-tree?id=$parent_id"
