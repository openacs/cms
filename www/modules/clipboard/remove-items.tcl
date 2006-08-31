ad_page_contract {
    Remove items from the clipboard

    @author Michael Steigman
    @creation-date March 2006
} {
    { item_id:multiple }
    { mount_point }
    { clip_tab }
}

set clip [cms::clipboard::parse_cookie]
foreach item $item_id {
    set clip [cms::clipboard::remove_item $clip $clip_tab $item]
}

ad_set_cookie content_marks [cms::clipboard::reassemble_cookie $clip]
cms::clipboard::free $clip

ad_returnredirect [export_vars -base index {mount_point clip_tab}]
