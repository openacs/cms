ad_page_contract {
    Delete a relationship

    @author Michael Steigman
    @creation-date October 2004
} {
    { rel_id:integer,multiple }
    { mount_point "sitemap" }
    { return_url "index" }
    { passthrough "[content::assemble_passthrough mount_point]" }
}

# request create
# request set_param rel_id -datatype integer
# request set_param mount_point -datatype keyword -value "sitemap"
# request set_param return_url -datatype text -value "index"
# request set_param passthrough -datatype text -value [content::assemble_passthrough mount_point]

set item_id ""
foreach rel $rel_id {

    # Get the item_id; determine if the relationship exists
    set item_id [db_string get_item_id "" -default ""]
    if { [string equal $item_id ""] } {
	db_abort_transaction
	request::error no_such_rel "The relationship $rel_id does not exist."
	return
    }
    # Check permissions
    content::check_access $item_id cm_relate \
	-mount_point $mount_point \
	-return_url "modules/sitemap/index"
    db_exec_plsql unrelate_item ""
    
}

lappend passthrough [list item_id $item_id]

template::forward "$return_url?item_props_tab=children[content::url_passthrough $passthrough]"
