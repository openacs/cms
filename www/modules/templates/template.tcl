# /cms/modules/templates/template.tcl

# Assemble information for a content item.  Note this page is only
# appropriate for revisioned content items.  Non-revisioned content
# items (symlinks, extlinks and folders) have separate admin pages

# Most information on this page is included via components.

# The mount_point is used to determine the proper root context
# when querying the path to the item.

request create -params {
  template_id -datatype integer
}

# The root ID is to determine the appropriate path to the item
set root_id [cm::modules::templates::getRootFolderID]


# resolve any symlinks
template::query get_id resolved_template_id onevalue "
  select content_symlink.resolve(:template_id) from dual
" 

set template_id $resolved_template_id

# get the path
template::query get_path path onevalue "
  select content_item.get_path(:template_id, :root_id) from dual
" 

# check for valid template_id
if { [template::util::is_nil path] } {
  ns_log Notice "/templates/template.tcl - BAD TEMPLATE_ID - $template_id"
  template::forward "../sitemap/index?mount_point=templates&id="
}


# get the context bar info

template::query context multirow "select
      t.tree_level, t.context_id, content_item.get_title(t.context_id) as title
    from (
      select 
        context_id, level as tree_level
      from 
        acs_objects
      where
        context_id <> 0
      connect by
        prior context_id = object_id
      start with
        object_id = :template_id
      ) t, cr_items i
    where
      i.item_id = t.context_id
    order by
      tree_level desc"


# find out which items this template is registered to
template::query get_items items multirow "
  select
    content_item.get_title(item_id) title, item_id, use_context
  from
    cr_item_template_map
  where
    template_id = :template_id
  order by
    use_context"


# find out which types this template is registered to
template::query get_types types multirow "
  select
    pretty_name, content_type, use_context
  from
    acs_object_types types, cr_type_template_map map
  where
    map.template_id = :template_id
  and
    types.object_type = map.content_type
  order by
    types.pretty_name"
