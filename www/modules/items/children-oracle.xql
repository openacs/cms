<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_child_types">      
      <querytext>

  select
    t.pretty_name, c.child_type
  from
    acs_object_types t, cr_type_children c
  where
    c.parent_type = content_item.get_content_type(:item_id)
  and
    c.child_type = t.object_type      

      </querytext>
</fullquery>

 
</queryset>
