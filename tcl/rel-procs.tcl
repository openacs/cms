
# @namespace cms_rel

# Procedures for managing relation items and child items

namespace eval cms_rel {}



ad_proc -public cms_rel::sort_related_item_order { item_id } {

 @public sort_related_item_order

 Resort the related items order for a given content item, ensuring that
  order_n is unique for an item_id.  Chooses new order based on the old
  order_n and then rel_id (the order the item was related)

 @author Michael Pih

 @param item_id The item for which to resort related items

} {

    db_transaction {

	# grab all related items ordered by order_n, rel_id
	template::query srio_get_related_items related_items onelist "
            select
              rel_id
            from
              cr_item_rels
            where
              item_id = :item_id
            order by
              order_n, rel_id
        " 

	# assign each related items a new order_n
	set i 0
	foreach rel_id $related_items {
	
	    db_dml "
  	        update cr_item_rels
                  set order_n = :i
                  where rel_id = :rel_id"

	    incr i
	}
    
    }
}


ad_proc -public cms_rel::sort_child_item_order { item_id } {

 @public sort_child_item_order

 Resort the child items order for a given content item, ensuring that
  order_n is unique for an item_id.  Chooses new order based on the old
  order_n and then rel_id (the order the item was related)

 @author Michael Pih

 @param item_id The item for which to resort child items

} {

    db_transaction {

	# grab all related items ordered by order_n, rel_id
	template::query scio_get_child_order child_items onelist "
            select
              rel_id
            from
              cr_child_rels
            where
              parent_id = :item_id
            order by
              order_n, rel_id
        " 

	# assign each related items a new order_n
	set i 0
	foreach rel_id $child_items {
	
	    db_dml "
  	        update cr_child_rels
                  set order_n = :i
                  where rel_id = :rel_id"

	    incr i
	}
    
    }
}
