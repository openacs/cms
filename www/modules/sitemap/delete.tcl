# Delete a folder (only if does not contain any items).
# Delete any symlinks pointing to this folder (possibly give a warning).

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value sitemap


set db [template::get_db_handle]

# permission check - user must have cm_write on this folder to delete it
content::check_access $id cm_write -user_id [User::getID] -db $db

# Determine if the folder is empty
template::query is_empty onevalue "
  select content_folder.is_empty(:id) from dual
" 

template::release_db_handle

# If nonempty, show error
if { [string equal $is_empty "f"] } {

  set message "This folder is not empty."
  set return_url "modules/sitemap/index"
  set passthrough [list [list id $id] [list parent_id $parent_id]]
  template::forward "../../error?message=$message&return_url=$return_url&passthrough=$passthrough"

} else {

  # Otherwise, delete the folder
  set db [template::begin_db_transaction]
  template::query delete_folder dml "begin content_folder.delete(:id); end;"
  template::end_db_transaction
  template::release_db_handle

  # Remove it from the clipboard, if it exists
  set clip [clipboard::parse_cookie]
  clipboard::remove_item $clip $mount_point $id
  clipboard::set_cookie $clip
  clipboard::free $clip 

  # Flush paginator cache
  cms_folder::flush $mount_point $parent_id

  template::forward "refresh-tree?id=$parent_id&goto_id=$parent_id&mount_point=$mount_point"
}
