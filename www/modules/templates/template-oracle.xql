<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_id">      
      <querytext>
      
  select content_symlink.resolve(:template_id) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_path">      
      <querytext>
      
  select content_item.get_path(:template_id, :root_id) from dual

      </querytext>
</fullquery>

 
<fullquery name="get_items">      
      <querytext>
      
  select
    content_item.get_title(item_id) title, item_id, use_context
  from
    cr_item_template_map
  where
    template_id = :template_id
  order by
    use_context
      </querytext>
</fullquery>

 
</queryset>
