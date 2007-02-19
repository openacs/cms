# expexts item_id, mount_point and tab

set user_id [ad_conn user_id]
set return_url [ad_return_url]

# form to allow creation of a *new* related item of an allowable type...
set related_types [db_list_of_lists get_related_types ""]

# but do not display form if this content type does not allow relations
set related_types_registered_p [llength $related_types]

if { [permission::permission_p -party_id $user_id -object_id $item_id -privilege write] } {
    form create add_related_item -method get -action create-1
    element create add_related_item parent_id -datatype integer \
	-widget hidden -value $item_id
    element create add_related_item return_url -datatype text \
	-widget hidden -value $return_url
    element create add_related_item content_type -datatype keyword \
	-options $related_types -widget select 
}

set relation cr_item_rel
template::list::create \
    -name related \
    -key rel_id \
    -bulk_action_export_vars {item_id relation}\
    -no_data "No related items" \
    -multirow related \
    -actions [list "Relate marked items to this item" \
		  [export_vars -base relate-items {item_id tab mount_point relation}] \
		  "Relate marks items to this item"] \
    -bulk_actions [list "Remove marked relations" \
		       [export_vars -base unrelate-item { rel_id mount_point}] \
		       "Remove marked relations from this item"] \
    -elements {
	title {
	    label "Title"
	    display_template { @related.title;noquote@ }
	    link_url_col title_url
	    link_html { title "View related item" }
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
		<nobr><a href=\"@related.move_up_url@\" title=\"Move item up\" class=\"button\">Move up</a>
		<a href=\"@related.move_down_url@\" title=\"Move item down\" class=\"button\">Move down</a></nobr>
	    }
	}
    }    

db_multirow -extend { title_url relation_view_url move_up_url move_down_url reorder } related get_related "" {
    set title_url [export_vars -base index {item_id mount_point}]
    set move_up_url [export_vars -base "relate-order?order=up&relation_type=relation" {rel_id mount_point tab}]
    set move_down_url [export_vars -base "relate-order?order=down&relation_type=relation" {rel_id mount_point tab}]
}
