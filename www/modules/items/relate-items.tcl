# This form will list all currently marked content items
# and confirm that the user wishes to link them all to the current item
request create -params {
    item_id -datatype integer
    relation -datatype text -optional -value cr_item_rel
    mount_point -datatype text -value sitemap
    tab -datatype text -value related
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $item_id -privilege write

set page_title "Relate Items to [content::item::get_title -item_id $item_id]"
set item_type [content::item::content_type -item_id $item_id]

# get related items from the clipboard
set clip [cms::clipboard::parse_cookie]
set items [cms::clipboard::get_items $clip $mount_point]

set type_options_list [db_list_of_lists get_relation_type_options {}]
set validation_proc "valid_${relation}_relation_p"
set target_item_num 0
multirow create target_items item_id title type_options tag_options
foreach clipped_item $items {
    if {[cms::rel::${validation_proc} -item_id $item_id -object_id $clipped_item]} {
	incr target_item_num
	set object_type [content::item::content_type -item_id $clipped_item]
	set tag_options "\n<select name=relation_tag.$target_item_num>\n"
	foreach option [db_list ${relation}_tag_options {}] {
	    append tag_options "<option value=$option>$option</option>\n"
	}
	append tag_options "</select>"
	
	set type_options "\n<select name=relation_type.$target_item_num>\n"
	foreach type_option $type_options_list {
	    append type_options "<option value=\"[lindex $type_option 1]\">[lindex $type_option 0]</option>\n"
	}
	append type_options "</select>"
	
	multirow append target_items $clipped_item "[content::item::get_title -item_id $clipped_item]" $type_options $tag_options
    }
}

if { $target_item_num eq 0 } {
    ad_returnredirect -message "No valid items on clipboard" [export_vars -base index {item_id tab}]
    ad_script_abort
}
