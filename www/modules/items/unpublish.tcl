# unpublish.tcl
# Publish a revision to the file system.

request create
request set_param item_id -datatype integer

set sql "begin 
           content_item.unset_live_revision( :item_id );
         end;"

publish::unpublish_item $item_id

set db [template::begin_db_transaction]
template::query unset_live_revision dml $sql
template::end_db_transaction
template::release_db_handle

template::forward "index?item_id=$item_id"