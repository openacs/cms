# Display information about items for which the item is the context.

# page variables
request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# create a form to add child items

set child_types [db_list_of_lists get_child_types ""]

# do not display template if this content type does not allow children
if { [llength $child_types] == 0 } { adp_abort }

if { [string equal $user_permissions(cm_new) t] } {
  form create add_child -method get -action "create-1"
  element create add_child parent_id -datatype integer \
    -widget hidden -value $item_id
  element create add_child content_type -datatype keyword \
    -options $child_types -widget select 
}

template::list::create \
    -name children \
    -key rel_id \
    -multirow children \
    -actions [list "Relate marked items to this item" \
		  "relate-items?item_id=$item_id" \
		  "Relate marks items to this item"] \
    -bulk_actions [list "Remove marked relations" \
		       "[export_vars -base unrelate-item?mount_point=sitemap { rel_id }]" \
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
	relation_view_url {
	    label "Tag"
	    display_template "<a href=\"@related.relation_view_url@\" title=\"View relation\">@related.tag@</a>"
	}
	reorder {
	    label "Move"
	    display_template "<nobr><a href=\"@related.move_up_url@\" title=\"Move item up\">up</a> &nbsp;|&nbsp; \
                                    <a href=\"@related.move_down_url@\" title=\"Move item down\">down</a></nobr>"
	}
    }    

db_multirow -extend { title_url relation_view_url move_up_url move_down_url reorder } children get_children "" {
    set title_url "index?item_id=$item_id&mount_point=$mount_point"
    set relation_view_url "relationship-view?rel_id=$rel_id&mount_point=$mount_point"
    set move_up_url "relate-order?rel_id=$rel_id&order=up&mount_point=$mount_point&item_props_tab=children&relation_type=relation"
    set move_down_url "relate-order?rel_id=$rel_id&order=down&mount_point=$mount_point&item_props_tab=children&relation_type=relation"
}
