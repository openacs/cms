ad_page_contract {
    Delete a relationship

    @author Michael Steigman
    @creation-date October 2004
} {
    { rel_id:integer,multiple }
    { mount_point:optional "sitemap" }
    { return_url:optional "index" }
    { tab:optional "related" }
}

set item_id ""
foreach rel $rel_id {

    # Get the item_id; determine if the relationship exists
    set item_id [db_string get_item_id "" -default ""]
    if { [string equal $item_id ""] } {
	db_abort_transaction
	ad_return_complaint "The relationship $rel_id does not exist."
	ad_script_abort
    }
    # Check permissions
    permission::require_permission -party_id [auth::require_login] \
	-object_id $item_id -privilege write
    content::item::unrelate -rel_id $rel
    
}

ad_returnredirect [export_vars -base $return_url {item_id mount_pount tab}]
