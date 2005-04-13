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
    permission::require_permission -party_id [auth::require_login] \
	-object_id $item_id -privilege write
    db_exec_plsql unrelate_item {}
    
}

lappend passthrough [list item_id $item_id]

set item_props_tab children
ad_returnredirect [export_vars -base $return_url {item_props_tab mount_pount}]
