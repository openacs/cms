<?xml version="1.0"?>
<queryset>

<fullquery name="publish::set_publish_status.sps_update_cr_items">      
      <querytext>
      update cr_items set publish_status = :new_status
                              where item_id = :item_id
      </querytext>
</fullquery>

 
<fullquery name="publish::render_subitem.rs_get_subitems">      
      <querytext>
      
      select 
        child_id
      from 
        cr_child_rels r, cr_items i
      where 
        r.parent_id = :main_item_id
      and 
        r.relation_tag = :relation_tag
      and
        i.item_id = r.child_id
      order by 
        order_n
      </querytext>
</fullquery>

 
<fullquery name="publish::render_subitem.cs_get_subitems_related">      
      <querytext>
      
      select 
        related_object_id
      from 
        cr_item_rels r, cr_items i
      where 
        r.item_id = :main_item_id
      and 
        r.relation_tag = :relation_tag
      and
        i.item_id = r.related_object_id 
      order by 
        r.order_n
      </querytext>
</fullquery>

 
<fullquery name="publish::handle::image.i_get_image_info">      
      <querytext>
      
    select 
      im.width, im.height, r.title as image_alt
    from 
      images im, cr_revisions r
    where 
      im.image_id = :revision_id
    and
      r.revision_id = :revision_id
  
      </querytext>
</fullquery>

 
</queryset>
