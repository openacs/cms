# Move the related item up or down

request create
request set_param rel_id -datatype integer
request set_param order         -datatype keyword 
request set_param mount_point   -datatype keyword -value "sitemap"
request set_param return_url    -datatype text    -value "index"
request set_param passthrough   -datatype text \
	-value [content::assemble_passthrough mount_point]
request set_param relation_type -datatype keyword -value "relation" 



# Use hardcoding instead of inheritance, since inheritance is not in the
# data model for some reason

if { [string equal $relation_type child] } {
    set rel_table           "cr_child_rels"
    set rel_parent_column   "parent_id"
} else {
    set rel_table           "cr_item_rels"
    set rel_parent_column   "item_id"
}


db_transaction {

    # Get item_id the related/child item
    template::query get_item_id item_id onevalue "
  select 
    $rel_parent_column
  from 
    $rel_table
  where 
    rel_id = :rel_id" 

    if { [template::util::is_nil item_id] } {
        db_abort_transaction
        request::error no_such_rel "The relationship $rel_id does not exist."
        return
    }

    template::util::array_to_vars rel_info
    lappend passthrough [list item_id $item_id]



    # Check permissions - must have cm_relate on the item
    content::check_access $item_id cm_relate \
        -mount_point $mount_point \
        -return_url "modules/sitemap/index"


    # Sort the related/child items order to ensure unique order_n
    if { [string equal $relation_type child] } {
        cms_rel::sort_child_item_order $item_id
    } else {
        cms_rel::sort_related_item_order $item_id
    }

    # grab the (sorted) order of the original related/child item
    template::query get_order order_n onevalue "
  select
    order_n
  from
    $rel_table
  where
    rel_id = :rel_id"


    # Move the relation up or down
    if { [string equal $order "up"] } {

        # Get the previous related/child
        template::query get_prev_swap_rel swap_rel onerow "
      select 
        rel_id, order_n 
      from 
        $rel_table
      where 
        $rel_parent_column = :item_id
      and 
        order_n = :order_n - 1"

    } else {

        # Get the next related/child item
        template::query get_next_swap_rel swap_rel onerow "
      select 
        rel_id, order_n 
      from 
        $rel_table
      where 
        $rel_parent_column = :item_id
      and 
        order_n = :order_n + 1"

    }


    # Only need to perform DML if the rel is not already at the top/bottom
    if { ![template::util::is_nil swap_rel] } {
        set swap_id $swap_rel(rel_id)
        set swap_order $swap_rel(order_n)

        db_dml relate_swap_1 "
      update $rel_table 
        set order_n = :swap_order 
        where rel_id = :rel_id"

        db_dml relate_swap_2 "
      update $rel_table 
        set order_n = :order_n 
        where rel_id = :swap_id"

    } else {
        ns_log notice "relate-order.tcl: $relation_type cannot be moved further"
    }
}

template::forward "$return_url?[content::url_passthrough $passthrough]"
