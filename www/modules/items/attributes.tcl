# display the attributes of an item

request create -params {
  revision_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# query the content type and table so we know which view to examine

set db [template::get_db_handle]

template::query type_info onerow "
  select 
    o.object_type, t.table_name 
  from 
    acs_objects o, acs_object_types t
  where 
    o.object_id = :revision_id
  and
    o.object_type = t.object_type
" -cache "revision_type_table $revision_id" \
  -persistent -timeout 86400

if { ! [info exists type_info(table_name)] } {
  template::release_db_handle
  adp_abort
  request error revision_id "Invalid Revision ID $revision_id"
  return
}

#  query the row from the standard view

template::query info onerow  "
  select
    content_item.get_revision_count(x.item_id) revision_count, 
    content_revision.get_number(:revision_id) revision_number, 
    content_item.get_live_revision(x.item_id) live_revision, 
    x.*
  from
    $type_info(table_name)x x
  where
    object_id = :revision_id"

if { ! [info exists info(item_id)] } {
  template::release_db_handle

  request error revision_id "Attributes for Revision ID
    $revision_id appear to be incomplete.  Each revision must have a 
    row in the storage table for its own content type, as well as in
    the storage table of all the supertypes of its content type."

  return
}

# Check permissions
content::check_access $info(item_id) cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# query the attributes for this content type

set content_type $type_info(object_type)

set query "
  select 
    types.pretty_name object_label, 
    types.table_name, 
    types.id_column, 
    attr.attribute_name, 
    attr.pretty_name attribute_label
  from 
    acs_attributes attr,
    ( select 
        object_type, pretty_name, table_name, id_column, 
        level as inherit_level
      from 
        acs_object_types
      where 
        object_type ^= 'acs_object'
      connect by 
        prior supertype = object_type
      start with 
        object_type = :content_type) types        
  where 
    attr.object_type = types.object_type
  order by 
    types.inherit_level desc"

template::query attributes multirow $query -eval {
  
    if { [catch { set value $info($row(attribute_name)) } errmsg] } {
	# catch - value doesn't exist
	set value "-"
    } 

    if { [string equal $value {}] } { set value "-" } 

    set row(attribute_value) $value
}

template::release_db_handle
