# /items/rename.tcl
# Change name of a content item

request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -value sitemap


# permissions check - cm_write required to rename an item
content::check_access $item_id cm_write -user_id [User::getID]

template::query get_item_name item_name onevalue "
  select 
    name
  from 
    cr_items
  where 
    item_id = :item_id
"

set page_title "Rename $item_name"

form create rename_item

element create rename_item mount_point \
  -datatype keyword \
  -widget hidden \
  -value $mount_point \
  -optional

element create rename_item item_id \
  -datatype integer \
  -widget hidden \
  -param

element create rename_item name \
  -label "Rename $item_name to:" \
  -datatype keyword \
  -widget text \
  -html { size 20 } \
  -validate { { expr ![string match $value "/"] } \
              { Item name cannot contain slashes }} \
  -value $item_name

# Rename
if { [form is_valid rename_item] } {

  form get_values rename_item \
	  mount_point item_id name

  set db [template::begin_db_transaction]
  db_transaction {
      db_exec_plsql rename_item "
    begin 
    content_item.rename (
        item_id => :item_id, 
        name    => :name 
    ); 
    end;"

      template::query get_parent_id parent_id onevalue "
    select
      parent_id
    from
      cr_items
    where
      item_id = :item_id" 
  }

  # flush cache
  cms_folder::flush $mount_point $parent_id

  template::forward "index?item_id=$item_id"
}
