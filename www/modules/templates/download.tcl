ad_page_contract {
    Return text of template to the browser
} {
    { template_id:integer }
    { edit_revision:integer,optional "[content::item::get_latest_revision -item_id $template_id]"}
}

ns_return 200 text/plain [content::get_content_value $edit_revision]
