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

 
</queryset>
