ad_page_contract {

    Delete or set message then redirect

} {
    { item_id:integer }
    { revision_id:integer,multiple }
    { action:optional "view" }
    { mount_point:optional "sitemap" }
    { tab:optional "revisions" }
    { return_url }
}

if { $action eq "view" } {
    set revision_name [content::revision::revision_name -revision_id $revision_id]
    util_user_message -message "$revision_name. Select \"Author Revision\" to base a new revision on this revision."
    if { $mount_point eq "templates" } {
	ad_returnredirect [export_vars -base ../templates/properties {item_id revision_id mount_point}]
    } else {
	ad_returnredirect [export_vars -base index {item_id revision_id mount_point}]
    }
    ad_script_abort
} else {

    set tab revisions
    # don't delete only/all revisions or live revision
    if { [content::item::get_revision_count -item_id $item_id] == [llength $revision_id] } {
	ad_returnredirect -message "Cannot delete all revisions. Delete the item instead." $return_url
	ad_script_abort
    }

    set live_revision [content::item::get_live_revision -item_id $item_id]
    foreach rev $revision_id {
	if { $rev == $live_revision } {
	    util_user_message -message "Cannot delete live revision"
	    continue
	}
	set revision_name [content::revision::revision_name -revision_id $rev]
	content::revision::delete -revision_id $revision_id
	util_user_message -message "$revision_name deleted"
    }

    if { $mount_point eq "templates" } {
	ad_returnredirect [export_vars -base ../templates/properties {item_id mount_point tab}]
    } else {
	ad_returnredirect [export_vars -base index {item_id mount_point tab}]
    }
    ad_script_abort
}
