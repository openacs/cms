# /modules/items/templates.tcl
# Display information about templates associated with the item.

request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap

set db [template::get_db_handle]

set user_id [User::getID]

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# check if the user has write permission on the types module
template::query can_set_default_template onevalue "
  select
    cms_permission.permission_p( module_id, :user_id, 'cm_write' )
  from
    cm_modules
  where
     key = 'types'
" 

template::query iteminfo onerow "
  select 
    object_type, pretty_name,
    content_item.get_title(:item_id) name
  from
    acs_object_types
  where 
    object_type = content_item.get_content_type(:item_id)
" 

set content_type $iteminfo(object_type)


# templates registered to this item
template::query registered_templates multirow "
  select 
    template_id, use_context, 
    content_item.get_path( template_id ) path,
    cms_permission.permission_p( template_id, :user_id, 'cm_examine')
      as can_read_template
  from 
    cr_item_template_map t
  where     
    t.item_id = :item_id
  order by 
    path, use_context
"

# templates registered to this content type
template::query type_templates multirow "
  select 
    template_id, use_context, is_default,
    content_item.get_path( template_id ) path,
    cms_permission.permission_p( template_id, :user_id, 'cm_examine') 
      as can_read_template,
    (select 1 
     from 
       cr_item_template_map itmap 
     where 
       itmap.template_id = t.template_id
     and 
       itmap.use_context = t.use_context
     and 
       itmap.item_id = :item_id) already_registered_p
  from 
    cr_type_template_map t
  where 
    t.content_type = :content_type
  order by 
    path, use_context
" 

template::release_db_handle

set return_url "index?item_id=$item_id&mount_point=sitemap"
