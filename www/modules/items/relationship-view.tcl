# View a relationship

request create -params {
  rel_id -datatype integer
  mount_point -datatype keyword -value sitemap -optional
}

# Get misc info

template::query rel_info onerow "
  select
    t.pretty_name as type_name, t.object_type, 
    r.item_id, r.related_object_id,\
    content_item.get_title(i.item_id) as item_title,
    acs_object.name(r.related_object_id) as related_title,
    content_item.is_subclass(o2.object_type, 'content_item') as is_item,
    r.relation_tag, r.order_n
  from
    acs_objects o, acs_object_types t, 
    cr_item_rels r, cr_items i, acs_objects o2
  where
    o.object_type = t.object_type
  and
    o.object_id = :rel_id
  and
    r.rel_id = :rel_id
  and 
    i.item_id = r.item_id
  and 
    o2.object_id = r.related_object_id
"

template::util::array_to_vars rel_info

# Get extra attributes

template::query rel_attrs multirow "         
  select 
    types.table_name, types.id_column, attr.attribute_name,
    attr.pretty_name as attribute_label, attr.datatype,
    types.pretty_name as type_name
  from 
    acs_attributes attr,
    (select 
        object_type, table_name, id_column, pretty_name,
        level as inherit_level
      from 
        acs_object_types
      where 
        object_type not in ('acs_object', 'cr_item_rel')
      connect by 
        prior supertype = object_type
      start with 
        object_type = :object_type) types
  where
    attr.object_type (+) = types.object_type
  order by
    inherit_level desc, attr.pretty_name
  "
 
# Get attribute values... inefficient !

for { set i 1 } { $i <= ${rel_attrs:rowcount} } { incr i } {
  upvar 0 "rel_attrs:$i" a_row

  if { [string equal $a_row(datatype) date] } {
    set what "to_char($a_row(attribute_name), 'Mon DD, YYYY HH24:MI') as value"
  } else {
    set what "$a_row(attribute_name) as value"
  }

  template::query value onevalue "
    select $what from $a_row(table_name) 
      where $a_row(id_column) = :rel_id" 

  set a_row(value) $value

}





