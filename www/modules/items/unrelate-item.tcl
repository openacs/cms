# Delete a relationship

request create
request set_param rel_id -datatype integer
request set_param mount_point -datatype keyword -value "sitemap"
request set_param return_url -datatype text -value "index"
request set_param passthrough -datatype text -value [content::assemble_passthrough mount_point]

set db [template::begin_db_transaction]

# Get the item_id; determine if the relationship exists
template::query item_id onevalue "
  select item_id from cr_item_rels where rel_id = :rel_id" 

if { [template::util::is_nil item_id] } {
  ns_db dml $db "abort transaction"
  template::release_db_handle
  request::error no_such_rel "The relationship $rel_id does not exist."
  return
}

# Check permissions
content::check_access $item_id cm_relate \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -db $db

lappend passthrough [list item_id $item_id]

template::query unrelate_item dml "
  begin
  content_item.unrelate ( 
      rel_id => :rel_id 
  );
  end;"

template::end_db_transaction
template::release_db_handle

template::forward "$return_url?[content::url_passthrough $passthrough]"
