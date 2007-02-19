# Delete a subject category

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value categories

# Determine if the folder is empty
set is_empty [db_string get_empty_status ""]

# If nonempty, show error
if { [string equal $is_empty "f"] } {

    util_user_message -message "This category contains subcategories and cannot be deleted."

} else {

  db_transaction {
      # Otherwise, delete the folder
      set delete_keyword [db_exec_plsql delete_keyword "begin :1 := content_keyword.del(:id); end;"]
  }

  # Remove it from the clipboard, if it exists
  set new_clip [cms::clipboard::remove_item [cms::clipboard::parse_cookie] $mount_point $id]
  ad_set_cookie content_marks [cms::clipboard::reassemble_cookie $new_clip]
  cms::clipboard::free $new_clip 

  ad_returnredirect "index?id=$parent_id&mount_point=$mount_point"
}
 
