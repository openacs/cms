<?xml version="1.0"?>
<queryset>

<fullquery name="second_template_p">      
      <querytext>
      
  select count(1) from cr_item_template_map
    where use_context = :context
    and item_id = :item_id
      </querytext>
</fullquery>

<fullquery name="get_contexts">      
      <querytext>
      
  select use_context, use_context from cr_template_use_contexts

      </querytext>
</fullquery>
 
</queryset>
