ad_page_contract {

    @author Michael Steigman
    @creation-date May 2005
} {
    { item_id:naturalnum }
    { mount_point "sitemap" }
    { item_props_tab:optional "editing" }
}

content::item::unset_live_revision -item_id $item_id
#publish::unpublish_item $item_id

ad_returnredirect [export_vars -base index {item_id item_props_tab mount_point}]

