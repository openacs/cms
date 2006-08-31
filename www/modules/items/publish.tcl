ad_page_contract {

    @author Michael Steigman
    @creation-date May 2005
} {
    { item_id:naturalnum }
    { revision_id:naturalnum }
    { mount_point "sitemap" }
    { tab:optional "revisions" }
}

content::item::set_live_revision -revision_id $revision_id
ad_returnredirect [export_vars -base index {item_id tab mount_point}]

# set root_path [ns_info pageroot]

# db_transaction {

#     db_1row get_iteminfo ""

#     if { [string equal $publish_p t] } {

#         # cms::publish::publish_revision $revision_id

#         db_exec_plsql set_live_revision {}
#         publish::unpublish_item $item_id
        
#     } else {

#         db_abort_transaction
# 	util_user_message -message "This item is not in a publishable state"

#     }
# }


