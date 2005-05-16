request create -params {
    item_id -datatype integer
    mount_point -datatype text -value sitemap
    item_props_tab -datatype text -optional
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $item_id -privilege read

template::list::create \
    -name related \
    -key rel_id \
    -no_data "No related items" \
    -multirow related \
    -actions [list "Relate marked items to this item" \
		  [export_vars -base relate-items {item_id item_props_tab mount_point}] \
		  "Relate marks items to this item"] \
    -bulk_actions [list "Remove marked relations" \
		       [export_vars -base unrelate-item?mount_point=sitemap { rel_id }] \
		       "Remove marked relations from this item"] \
    -elements {
	content_type {
	    label "Content Type"
	}
	title_url {
	    label "Title"
	    display_template "<a href=\"@related.title_url@\" title=\"View content item\">@related.title@</a>"
	}
	type_name {
	    label "Relationship Type"
	}
	tag {
	    label "Tag"
	}
	reorder {
	    label "Move"
	    display_template "<nobr><a href=\"@related.move_up_url@\" title=\"Move item up\">up</a> &nbsp;|&nbsp; \
                                    <a href=\"@related.move_down_url@\" title=\"Move item down\">down</a></nobr>"
	}
    }    

db_multirow -extend { title_url relation_view_url move_up_url move_down_url reorder } related get_related "" {
    set title_url "index?item_id=$item_id&mount_point=$mount_point"
    set move_up_url "relate-order?rel_id=$rel_id&order=up&mount_point=$mount_point&item_props_tab=related&relation_type=relation"
    set move_down_url "relate-order?rel_id=$rel_id&order=down&mount_point=$mount_point&item_props_tab=related&relation_type=relation"
}

