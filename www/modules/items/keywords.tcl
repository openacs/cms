# Display a list of keywords for the item

# page variables
template::request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value "sitemap"
}

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error


template::query get_name name onevalue "select name from cr_items where item_id = :item_id"

template::query get_keywords keywords multirow "select
             keyword_id,
             content_keyword.get_heading(keyword_id) heading,
             NVL(content_keyword.get_description(keyword_id),
                '-') description
           from
             cr_item_keyword_map
           where
             item_id = :item_id
           order by
             heading"

set page_title "Content Keywords for $name"
