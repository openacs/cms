# Display a list of revisions for the item

# page variables
template::request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# pagination vars
template::request set_param page -datatype integer -value 1

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# add content html
template::query get_content_type content_type onevalue "
  select
    content_item.get_content_type( :item_id )
  from
    dual
" 


# get item info

template::query get_iteminfo iteminfo onerow "
  select 
    item_id, name, locale, live_revision, publish_status,
    content_item.is_publishable(item_id) as is_publishable
  from 
    cr_items
  where 
    item_id = :item_id"
template::util::array_to_vars iteminfo


# get all revisions

template::query get_revisions revisions multirow [pagination::paginate_query "
  select 
    revision_id, 
    trim(title) as title, 
    trim(description) as description,
    content_revision.get_number(revision_id) as revision_number
  from 
    cr_revisions r
  where 
    r.item_id = :item_id
  order by
    revision_number desc" $page]

set total_pages [pagination::get_total_pages $db]

set pagination_html [pagination::page_number_links $page $total_pages]
