ad_library {
    Procedures for managing related/child items
}

# @namespace cms::rel
namespace eval cms::rel {}

ad_proc -public cms::rel::sort_related_item_order { item_id } {

 @public sort_related_item_order

 Resort the related items order for a given content item, ensuring that
  order_n is unique for an item_id.  Chooses new order based on the old
  order_n and then rel_id (the order the item was related)

 @author Michael Pih

 @param item_id The item for which to resort related items

} {

    db_transaction {

	# grab all related items ordered by order_n, rel_id
        set related_items [db_list get_related_items ""]

	# assign each related items a new order_n
	set i 0
	foreach rel_id $related_items {
	
	    db_dml reorder {}

	    incr i
	}
    
    }
}


ad_proc -public cms::rel::sort_child_item_order { item_id } {

 @public sort_child_item_order

 Resort the child items order for a given content item, ensuring that
  order_n is unique for an item_id.  Chooses new order based on the old
  order_n and then rel_id (the order the item was related)

 @author Michael Pih

 @param item_id The item for which to resort child items

} {

    db_transaction {

	# grab all related items ordered by order_n, rel_id
        set child_items [db_list get_child_order ""]

	# assign each related items a new order_n
	set i 0
	foreach rel_id $child_items {
	
	    db_dml reorder {}

	    incr i
	}
    
    }
}

ad_proc -public cms::rel::valid_cr_item_rel_relation_p {
    -item_id:required
    -object_id:required
} {
    Determine if target item can be related to item
    @return boolean
} {
    set content_type [content::item::content_type -item_id $item_id]
    set target_type [content::item::content_type -item_id $object_id]
    return [db_string valid_relation_p {} -default 0]
}

ad_proc -public cms::rel::valid_cr_item_child_rel_relation_p {
    -item_id:required
    -object_id:required
} {
    Determine if target item can be related to item
    @return boolean
} {
    set parent_type [content::item::content_type -item_id $item_id]
    set child_type [content::item::content_type -item_id $object_id]
    return [db_string valid_relation_p {} -default 0]
}

ad_proc -public cms::rel::add_child {
    -item_id:required
    -object_id:required
    -relation_tag:required
    -relation_type:required
    -order_n:required
} {
    Add a child (object_id) to item_id. Why is this stuff not in the CR?
} {
    set title "$relation_tag: $item_id - $object_id"
    db_transaction {
	set rel_id [package_exec_plsql -var_list \
			[list \
			     [list object_id null ]  \
			     [list object_type cr_item_child_rel ]  \
			     [list creation_date null]  \
			     [list creation_user null]  \
			     [list creation_ip null]  \
			     [list context_id $item_id]  \
			     [list title $title] \
			    ] acs_object new]
	db_dml add_child {}
    }
}

ad_proc -public cms::rel::remove_child {
    -rel_id:required
} {
    Remove child 
} {
    db_transaction {
	db_dml remove_child {}
	package_exec_plsql -var_list [list rel_id $rel_id ] acs_rel delete
    }
}
