# Add a template of the item

request create
request set_param item_id -datatype integer
request set_param template_id -datatype integer
request set_param context -datatype keyword


db_transaction {

    # check to make sure that no template is already registered
    #   to this item in this context
    template::query second_template_p second_template_p onevalue "
  select count(1) from cr_item_template_map
    where use_context = :context
    and item_id = :item_id"

    if { $second_template_p == 0 } {
        if { [catch { template::query template_register dml "begin content_item.register_template(
            item_id     => :item_id,
            template_id => :template_id,
            use_context => :context ); 
         end;"} err_msg] } {
            ns_log notice "template-register.tcl got an error: $err_msg"
        }
    }
}

forward "../items/index?item_id=$item_id&#templates"
