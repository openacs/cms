<?xml version="1.0"?>
<queryset>

<fullquery name="get_content_types">      
      <querytext>

	select content_type, pretty_name, is_default 
          from acs_object_types ao join cr_type_template_map ttm on (ao.object_type = ttm.content_type) 
         where template_id = :template_id

      </querytext>
</fullquery>

</queryset>
