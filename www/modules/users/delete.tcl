# Delete a subgroup

template::request create
template::request set_param id -datatype keyword
template::request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value users

# Determine if the group is empty
template::query is_empty onevalue "
  select NVL((select 'f' from dual where exists (
            select 1 from acs_rels 
              where object_id_one = :id 
              and rel_type in ('composition_rel', 'membership_rel'))),
          't') as is_empty from dual"

# If nonempty, show error
if { [string equal $is_empty "f"] } {

  set message "This group is not empty."
  set return_url "modules/sitemap/index"
  set passthrough [list [list id $id] [list parent_id $parent_id]]
  template::forward "../../error?message=$message&return_url=$return_url&passthrough=$passthrough"

} else {

  # Otherwise, delete the group
  set db [template::begin_db_transaction]
  template::query delete_group dml "begin acs_group.delete(:id); end;"
  template::end_db_transaction
  template::release_db_handle

  # Remove it from the clipboard, if it exists
  set clip [clipboard::parse_cookie]
  clipboard::remove_item $clip $mount_point $id
  clipboard::set_cookie $clip
  clipboard::free $clip 

  template::forward "refresh-tree?id=$parent_id&goto_id=$parent_id&mount_point=$mount_point"
}






