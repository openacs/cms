# Add a template of the item

request create
request set_param item_id -datatype integer
request set_param template_id -datatype integer
request set_param context -datatype text


set sql "begin
         content_item.unregister_template(
             template_id => :template_id, 
             item_id     => :item_id, 
             use_context => :context ); 
         end;"


set db [template::begin_db_transaction]
if { [catch { template::query template_unregiser dml $sql } err_msg] } {
    ns_log notice "template-remove.tcl got an error: $err_msg"
}
template::end_db_transaction
template::release_db_handle

template::forward "../items/index?item_id=$item_id&#templates"
