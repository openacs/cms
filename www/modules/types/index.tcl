# query for attributes of this subclass of content_revision and display them

request create
request set_param id -datatype keyword -value content_revision
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -value types
request set_param refresh_tree -datatype keyword -optional -value t

# Tree hack
if { [string equal $id content_revision] } {
  set refresh_id ""
} else {
  set refresh_id $id
}

set content_type $id
set user_id [User::getID]
set root_id [cm::modules::templates::getRootFolderID]

set db [template::get_db_handle]

query module_id onevalue "
  select module_id from cm_modules where key = 'types'
" 

content::check_access $module_id cm_examine -user_id $user_id -db $db

set can_edit_widgets $user_permissions(cm_write)


# get the content type pretty name
query object_type_pretty onevalue "
  select 
    pretty_name
  from
    acs_object_types
  where
    object_type = :content_type
" 


if { [string equal $object_type_pretty ""] } {
    # error - invalid content_type
    template::release_db_handle
    template::forward index
}


# get all the content types that this content type inherits from
query content_type_tree multirow "
  select 
    decode (supertype, 'acs_object', '', supertype) as parent_type,   
    decode (object_type, 'content_revision', '', object_type) as object_type,
    pretty_name
  from 
    acs_object_types
  where
    object_type ^= 'acs_object'
  connect by 
    object_type = prior supertype
  start with 
    object_type = :content_type
  order by 
    rownum desc
" 

# get all the attribute properties for this object_type
query attribute_types multirow "
  select 
    attr.attribute_id, attr.attribute_name, attr.object_type,
    attr.pretty_name as attribute_name_pretty,
    datatype, types.pretty_name as pretty_name,
    nvl(description_key,'&nbsp') as description_key, 
    description, widget
  from 
    acs_attributes attr, acs_attribute_descriptions d,
    cm_attribute_widgets w,
    ( select 
        object_type, pretty_name
      from 
        acs_object_types
      where 
        object_type ^= 'acs_object'
      connect by 
        prior supertype = object_type
      start with 
        object_type = :content_type
    ) types        
  where 
    attr.object_type = types.object_type
  and
    attr.attribute_id = w.attribute_id(+)
  and 
    attr.attribute_name = d.attribute_name(+)
  order by 
    types.object_type, sort_order, attr.attribute_name
" 

# get template information
query type_templates multirow "
  select 
    template_id, ttmap.content_type, use_context, is_default, name, 
    content_item.get_path(
      template_id,:root_id) as path,
    (select pretty_name 
       from acs_object_types 
       where object_type = :content_type) pretty_name
  from 
    cr_type_template_map ttmap, cr_items i 
  where 
    i.item_id = ttmap.template_id
  and 
    ttmap.content_type = :content_type
  order by 
    upper(name)
" 

template::release_db_handle

set page_title "Content Type - $object_type_pretty"

# for the permissions include
set return_url [ns_conn url]
set passthrough [content::assemble_passthrough return_url mount_point id]

# for templates table
if { [string equal $user_permissions(cm_write) t] } {
    set footer "<a href=\"register-templates?content_type=$content_type\">
    Register marked templates to this content type</a>"
} else {
    set footer ""
}

# Create the tabbed dialog
set url [ns_conn url]
append url "?id=$id&mount_point=$mount_point&parent_id=$parent_id&refresh_tree=f"

template::tabstrip create type_props -base_url $url
template::tabstrip add_tab type_props attributes "Attributes and Uploads" attributes
template::tabstrip add_tab type_props relations "Relation Types" relations
template::tabstrip add_tab type_props templates "Templates" templates
template::tabstrip add_tab type_props permissions "Permissions" permissions

