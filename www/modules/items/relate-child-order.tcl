# Move the related item up or down

request create
request set_param rel_id -datatype integer
request set_param order -datatype keyword 
request set_param mount_point -datatype keyword -optional -value "sitemap"
request set_param return_url -datatype text -optional -value "index"
request set_param passthrough -datatype text -optional -value [content::assemble_passthrough mount_point]

db_transaction {
    # Get the irelated items
    template::query get_rel_info rel_info onerow "
  select parent_id as item_id, order_n from cr_child_rels 
  where rel_id = :rel_id" 

    if { ![info exists rel_info] } {
        db_dml abort "abort transaction"
        request::error no_such_rel "The relationship $rel_id does not exist."
        return
    }

    template::util::array_to_vars rel_info
    lappend passthrough [list item_id $item_id]

    # Move the relation up:

    if { [string equal $order up] } {
        # Get the previous item's order
        template::query get_prev_swap_rel swap_rel onerow "
    select rel_id, order_n from cr_child_rels r1
    where r1.parent_id = :item_id
    and r1.order_n < :order_n 
    and not exists (select order_n from cr_child_rels r2
                    where r2.parent_id = :item_id
                    and r2.order_n < :order_n
                    and r2.order_n > r1.order_n)" 
    } else {
        # Get the next item's order
        template::query get_next_swap_rel swap_rel onerow "
    select rel_id, order_n from cr_child_rels r1
    where r1.parent_id = :item_id
    and r1.order_n > :order_n 
    and not exists (select order_n from cr_child_rels r2
                    where r2.parent_id = :item_id
                    and r2.order_n > :order_n
                    and r2.order_n < r1.order_n)" 
    }

    # Only need to perform DML if the rel is not already at the top/bottom
    if { [info exists swap_rel] } {

        set swap_id $swap_rel(rel_id)
        set swap_order $swap_rel(order_n)

        db_dml child_swap_1 "
    update cr_child_rels set order_n = :swap_order where rel_id = :rel_id
  "
        db_dml child_swap_2 "
    update cr_child_rels set order_n = :order_n where rel_id = :swap_id
  "
    } else {
        ns_log notice "ORDER: Relation cannot be moved further"
    }
}

template::forward "$return_url?[content::url_passthrough $passthrough]"



  




