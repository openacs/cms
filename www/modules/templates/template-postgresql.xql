<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_id">      
      <querytext>
      
  select content_symlink__resolve(:template_id) 

      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      
  select content_item__get_path(:template_id, :root_id) 

      </querytext>
</fullquery>

 
<fullquery name="get_items">      
      <querytext>
      
  select
    content_item__get_title(item_id, 'f') as title, item_id, use_context
  from
    cr_item_template_map
  where
    template_id = :template_id
  order by
    use_context
      </querytext>
</fullquery>

<fullquery name="get_items">      
      <querytext>

select
      t.tree_level, t.context_id, content_item__get_title(t.context_id) as title
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
      tree_level desc

       </querytext>
</fullquery>
 
</queryset>
