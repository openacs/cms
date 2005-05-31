# /cms/www/modules/items/publish-status.tcl
# Indicates whether or not the item is publishable and displays
#   what needs to be done before this item can be published.
request create
request set_param item_id -datatype integer
request set_param item_props_tab -datatype text

set user_id [auth::require_login]
permission::require_permission -party_id $user_id -object_id $item_id \
    -privilege read

set can_edit_status_p [permission::permission_p -party_id $user_id \
			   -object_id $item_id -privilege write]

# Query for publish status and release schedule, if any
db_1row get_info "" -column_array info

set publish_status [ad_decode $info(publish_status) "" production $info(publish_status)]
set starting [ad_decode $info(start_when) "" immediately ""]
set ending [ad_decode $info(end_when) "" indefinitely ""]

# Build a sentence describing the publishing status
switch $publish_status {
    
    production { 
	set message "This item is in production."
    }
    
    ready { 
	set message "This item is ready for publishing. "
	if { ! [string equal $starting immediately] } {
	    append message "It has been scheduled for release
                      on [lc_time_fmt $info(start_when) \"%q %X\"]."
	} else {
	    append message "It has not been scheduled for release."
	}
    }
    
    live { 
	set message "This item has been published. "
	if { ! [string equal $ending indefinitely] } {
	    append message "It has been scheduled to expire
                        on [lc_time_fmt $info(end_when) \"%q %X\"]."
	} else {
	    append message "It has no expiration date."
	}
    }
    
    expired { 
	set message "This item is expired."
    }
}

set live_revision [content::item::get_live_revision -item_id $item_id]
set latest_revision [content::item::get_latest_revision -item_id $item_id]
set is_publishable [content::item::is_publishable -item_id $item_id]

# determine if child type constraints have been satisfied
set unpublishable_child_types 0
db_multirow -extend {is_fulfilled difference direction} child_types get_child_types {} {

    # set is_fulfilled to t if the relationship constraints are fulfilled
    #   otherwise set is_fulfilled to f

    # keep track of numbers
    #  difference - the (absolute) number of child items in excess or lack
    #  direction  - whether "more" or "less" child items are needed

    set is_fulfilled t
    set difference 0
    set direction ""

    if { $child_count < $min_n } {
	set is_fulfilled f
	incr unpublishable_child_types
	set difference [expr $min_n - $child_count]
	set direction more
    }
    if { ![string equal {} $max_n] && $child_count > $max_n } {
	set row(is_fulfilled) f
	incr unpublishable_child_types
	set difference [expr $child_count - $max_n]
	set direction less
    }
}

# determine if relation type constraints have been satisfied
set unpublishable_rel_types 0
db_multirow -extend { is_fulfilled difference direction } rel_types get_rel_types {} {

    # set is_fulfilled to t if the relationship constraints are fulfilled
    #   otherwise set is_fulfilled to f

    # keep track of numbers
    #  difference - the (absolute) number of related items in excess or lack
    #  direction  - whether "more" or "less" related items are needed

    set is_fulfilled t
    set difference 0
    set direction ""

    if { $rel_count < $min_n } {
	set is_fulfilled f
	incr unpublishable_rel_types
	set difference [expr $min_n - $rel_count]
	set direction more
    }
    if { ![string equal {} $max_n] && $rel_count > $max_n } {
	set is_fulfilled f
	incr unpublishable_rel_types
	set difference [expr $rel_count - $max_n]
	set direction less
    }

}
