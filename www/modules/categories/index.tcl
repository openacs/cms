# Index page for keywords

request create -params {
  id -datatype keyword -optional
  mount_point -datatype keyword -optional -value categories
  parent_id -datatype keyword -optional
}

set original_id $id

set img_checked "[ad_conn package_url]resources/checked.gif"

# Create all the neccessary URL params for passthrough
set passthrough "mount_point=$mount_point&parent_id=$parent_id"

set root_id [cm::modules::${mount_point}::getRootFolderID]
if { [util::is_nil id] || [string equal $id _all_] } {
  set where_clause "k.parent_id is null"
} else {
  set where_clause "k.parent_id = :id"
}

# Get self

if { ![util::is_nil id] && ![string equal $id _all_] } {
  template::query get_info info onerow "
    select 
      content_keyword.is_leaf(:id) as is_leaf,
      content_keyword.get_heading(:id) as heading,
      content_keyword.get_description(:id) as description,
      content_keyword.get_path(:id) as path
    from 
      dual"
} else {
  set info(is_leaf) "f"
  set info(heading) ""
  set info(description) "You can create content categories here
in order to classify content items."
  set info(path) "/"
}

if { [string equal $info(is_leaf) t] } {
  set what "keyword"
} else {
  set what "category"
}

set clip [clipboard::parse_cookie]

# Get children
template::query get_items items multirow "
  select
    keyword_id,
    content_keyword.is_leaf(keyword_id) as is_leaf,
    content_keyword.get_heading(keyword_id) as heading,
    (select count(*) from cr_item_keyword_map m
      where m.keyword_id = k.keyword_id) as item_count
  from
    cr_keywords k
  where
    $where_clause
  order by
    is_leaf, heading
" 
ns_log Notice "id = $id"
# Get the parent id if it is missing
if { [util::is_nil parent_id] && ![util::is_nil id] } {
  template::query get_parent_id parent_id onevalue "
    select
      context_id
    from
      acs_objects
    where
      object_id = :id"
}






