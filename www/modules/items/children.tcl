# Display information about items for which the item is the context.

# page variables
request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# Check permissions
content::check_access $item_id cm_examine \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# create a form to add child items

template::query get_child_types child_types multilist "
  select
    t.pretty_name, c.child_type
  from
    acs_object_types t, cr_type_children c
  where
    c.parent_type = content_item.get_content_type(:item_id)
  and
    c.child_type = t.object_type"

# do not display template if this content type does not allow children
if { [llength $child_types] == 0 } { adp_abort }

if { [string equal $user_permissions(cm_new) t] } {
  form create add_child -method get -action "create-1"
  element create add_child parent_id -datatype integer \
    -widget hidden -value $item_id
  element create add_child content_type -datatype keyword \
    -options $child_types -widget select 
}

set query "
  select
    rel_id, relation_tag, 
    i.item_id, i.name, trim(r.title) as title, t.pretty_name, 
    to_char(o.creation_date, 'MM/DD/YY HH24:MM') last_modified
  from
    cr_items i, acs_object_types t, acs_objects o, cr_revisions r,
    cr_child_rels c
  where
    i.parent_id = :item_id
  and
    o.object_id = :item_id
  and
    i.content_type = t.object_type
  and
    r.revision_id = NVL(i.live_revision, i.latest_revision)
  and
    c.parent_id = i.parent_id
  and
    c.child_id = i.item_id
  order by
    t.pretty_name, title"

#template::query children multirow $query




template::query get_children children multirow "
  select
    r.rel_id,
    r.child_id item_id,
    t.pretty_name as type_name,
    NVL(r.relation_tag, '-') as tag,
    trim(NVL(content_item.get_title(r.child_id), i.name)) title,
    ot.pretty_name as content_type
  from
    cr_child_rels r, acs_objects o, acs_object_types t,
    cr_items i, acs_object_types ot
  where
    r.parent_id = :item_id
  and
    o.object_id = r.rel_id
  and
    t.object_type = o.object_type
  and 
    i.item_id = r.child_id
  and
    ot.object_type = i.content_type
  order by 
    order_n, title
" 
