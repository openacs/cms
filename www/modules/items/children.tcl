# expects item_id and (optionally) mount_point

set user_id [ad_conn user_id]
set return_url [ad_return_url]

# create a form to add child items...
set child_types [db_list_of_lists get_child_types ""]

# but do not display form if this content type does not allow children
set child_types_registered_p [llength $child_types]

if { [permission::permission_p -party_id $user_id -object_id $item_id -privilege write] } {
    form create add_child -method get -action create-1
    element create add_child parent_id -datatype integer \
	-widget hidden -value $item_id
    element create add_child return_url -datatype text \
	-widget hidden -value $return_url
    element create add_child content_type -datatype keyword \
	-options $child_types -widget select 
}

set relation cr_item_child_rel
template::list::create \
    -name children \
    -key rel_id \
    -bulk_action_export_vars {item_id relation}\
    -no_data "No child items" \
    -multirow children \
    -actions [list "Relate marked items to this item" \
		  [export_vars -base relate-items {item_id relation mount_point}] \
		  "Relate marks items to this item"] \
    -bulk_actions [list "Remove marked relations" \
		       [export_vars -base unrelate-item {item_id rel_id mount_point}] \
		       "Remove marked relations from this item"] \
    -elements {
	title {
	    label "Title"
	    display_template { @children.title;noquote@ }
	    link_url_col title_url
	    link_html { title "View child item" }
	}
	type_name {
	    label "Relationship Type"
	}
	content_type {
	    label "Content Type"
	}
	tag {
	    label "Tag"
	}
	reorder {
	    display_template {
		<nobr><a href=\"@children.move_up_url@\" title=\"Move item up\" class=\"button\">Up</a>
		<a href=\"@children.move_down_url@\" title=\"Move item down\" class=\"button\">Down</a></nobr>
	    }
	}
    }    

db_multirow -extend { title_url relation_view_url move_up_url move_down_url reorder } children get_children "" {
    set title_url [export_vars -base index {item_id mount_point}]
    set move_up_url "relate-order?rel_id=$rel_id&order=up&mount_point=$mount_point&tab=children&relation_type=relation"
    set move_down_url "relate-order?rel_id=$rel_id&order=down&mount_point=$mount_point&tab=children&relation_type=relation"
}
