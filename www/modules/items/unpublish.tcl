ad_page_contract {

    @author Michael Steigman
    @creation-date May 2005
} {
    { item_id:naturalnum }
    { mount_point "sitemap" }
    { tab:optional "revisions" }
}

content::item::unset_live_revision -item_id $item_id
#cms::publish::unpublish_item $item_id

ad_returnredirect [export_vars -base index {item_id tab mount_point}]

