
# @namespace cms_rel

# Procedures for managing relation items and child items

namespace eval cms_rel {}


# @public sort_related_item_order

# Resort the related items order for a given content item, ensuring that
#  order_n is unique for an item_id.  Chooses new order based on the old
#  order_n and then rel_id (the order the item was related)

# @author Michael Pih

# @param item_id The item for which to resort related items

proc cms_rel::sort_related_item_order { item_id } {

    set db [template::begin_db_transaction]

    # grab all related items ordered by order_n, rel_id
    template::query related_items onelist "
      select
        rel_id
      from
        cr_item_rels
      where
        item_id = :item_id
      order by
        order_n, rel_id
    " -db $db

    # assign each related items a new order_n
    set i 0
    foreach rel_id $related_items {
	
	ns_ora dml $db "
	  update cr_item_rels
            set order_n = :i
            where rel_id = :rel_id"

	incr i
    }
    
    template::end_db_transaction
}



# @public sort_child_item_order

# Resort the child items order for a given content item, ensuring that
#  order_n is unique for an item_id.  Chooses new order based on the old
#  order_n and then rel_id (the order the item was related)

# @author Michael Pih

# @param item_id The item for which to resort child items

proc cms_rel::sort_child_item_order { item_id } {

    set db [template::begin_db_transaction]

    # grab all related items ordered by order_n, rel_id
    template::query child_items onelist "
      select
        rel_id
      from
        cr_child_rels
      where
        parent_id = :item_id
      order by
        order_n, rel_id
    " -db $db

    # assign each related items a new order_n
    set i 0
    foreach rel_id $child_items {
	
	ns_ora dml $db "
	  update cr_child_rels
            set order_n = :i
            where rel_id = :rel_id"

	incr i
    }
    
    template::end_db_transaction
}
