ad_page_contract {

    Relate target items to item_id

    @author Michael Steigman
    @creation-date February 2007
} {
    { target_items:integer,multiple ""}
    { item_id:integer }
    { target_item_id:integer,array,optional }    
    { relate_p:array "" }
    { relation_type:array "" }
    { relation_tag:array "" } 
    { order_n:array "" }    
    { tab:optional "related" }
}

set item_title [content::item::get_title -item_id $item_id]

set num_related 0
# loop through target items, check if they can be related
#  - if possible, do so. tell the user in either case.
foreach target_item_num $target_items {
    if { [info exists relate_p($target_item_num)] } {
	set target_title [content::item::get_title -item_id $target_item_id($target_item_num)]
	set relation [lindex [array get relation_type $target_item_num] 1]
	set proc "valid_${relation}_relation_p"
	if { [cms::rel::${proc} -item_id $item_id -object_id $target_item_id($target_item_num)] } {
	    switch $relation {
		cr_item_rel {
		    cms::rel::sort_related_item_order $item_id
		    content::item::relate -item_id $item_id \
			-object_id $target_item_id($target_item_num) \
			-relation_tag $relation_tag($target_item_num) \
			-relation_type $relation_type($target_item_num) \
			-order_n $order_n($target_item_num)
		}
		cr_item_child_rel {
		    cms::rel::sort_child_item_order $item_id
		    cms::rel::add_child -item_id $item_id \
			-object_id $target_item_id($target_item_num) \
			-relation_tag $relation_tag($target_item_num) \
			-relation_type $relation_type($target_item_num) \
			-order_n $order_n($target_item_num)
		}
	    }
	    util_user_message -message "Related $target_title to $item_title"
	    incr num_related
	} else {
	    util_user_message -message "Could not relate $target_title to $item_title"
	}
    }
}

if { $num_related == 0 } {
    util_user_message -message "Unable to relate any items"
}

ad_returnredirect [export_vars -base index {item_id tab}]

