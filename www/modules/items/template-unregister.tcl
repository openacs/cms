ad_page_contract {

    @author Michael Steigman
    @creation-date May 2005

} {
    { item_id:naturalnum }
    { template_id:naturalnum }
    { context }
    { mount_point:optional "sitemap" }
    { item_props_tab:optional "publishing" }
}

content::item::unregister_template -item_id $item_id \
    -template_id $template_id -use_context $context

ad_returnredirect [export_vars -base index {item_id mount_point item_props_tab}]
