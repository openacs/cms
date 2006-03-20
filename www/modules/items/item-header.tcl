request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap

content::item::get -item_id $item_id -revision latest -array_name content_item
set path "[subsite::get_element -subsite_id [ad_conn subsite_id] -element url -notrailing][content::item::get_path -item_id $item_id]"
set page_title "Content Item - $content_item(title)"
