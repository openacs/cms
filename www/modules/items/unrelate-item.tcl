ad_page_contract {
    Delete a relationship

    @author Michael Steigman
    @creation-date October 2004
} {
    { rel_id:integer,multiple }
    { item_id:integer }
    { relation }
    { mount_point:optional "sitemap" }
    { return_url:optional "index" }
    { tab:optional "related" }
}

set rel_table [ad_decode $relation cr_item_rel cr_item_rels cr_item_child_rel cr_child_rels ""]
foreach rel $rel_id {
    # determine if the relationship exists
    if { [db_string rel_exists_p {} -default 0] } {
	# check permissions
	permission::require_permission -party_id [auth::require_login] \
	    -object_id $item_id -privilege write
	if { $relation eq "cr_item_rel" } {
	    content::item::unrelate -rel_id $rel
	} else {
	    cms::rel::remove_child -rel_id $rel    
	}
    } else {
	ad_return_complaint 0 "The relationship $rel_id does not exist."
	ad_script_abort
    }   
}

ad_returnredirect [export_vars -base $return_url {item_id mount_pount tab}]
