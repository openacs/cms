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
set resolved_template_id [db_string get_id ""]

set template_id $resolved_template_id

# get the path
set path [db_string get_path "" -default ""]

# check for valid template_id
if { [string equal $path ""] } {
  ns_log Notice "/templates/template.tcl - BAD TEMPLATE_ID - $template_id"
  template::forward "../sitemap/index?mount_point=templates&id="
}


# get the context bar info
# FIXME: postgresql query needs to be fixed
template::query get_context context multirow "select
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
db_multirow items get_items ""

# find out which types this template is registered to
db_multirow types get_types ""
