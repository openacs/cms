<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="item::get_best_revision.gbr_get_best_revision">      
      <querytext>
      
    select content_item__get_best_revision(:item_id) 
  
      </querytext>
</fullquery>

 
<fullquery name="item::get_url.gu_get_path">      
      <querytext>
      
    select content_item__get_path(:item_id) 
  
      </querytext>
</fullquery>

 
<fullquery name="item::get_template_id.gti_get_template_id">      
      <querytext>
      
    select content_item__get_template(:item_id, :context) as template_id
    
      </querytext>
</fullquery>

 
<fullquery name="item::is_publishable.ip_is_publishable_p">      
      <querytext>
      
    select content_item__is_publishable(:item_id) 
  
      </querytext>
</fullquery>

 
<fullquery name="item::get_title.gt_get_title">      
      <querytext>
      
    select content_item__get_title(:item_id) 
  
      </querytext>
</fullquery>

<partialquery name="item::get_id.gi_get_item_id_1">
	<querytext>
	select content_item__get_id(:url
	</querytext>
</partialquery>

<partialquery name="item::get_id.gi_get_item_id_2">
	<querytext>
	, :root_folder
	</querytext>
</partialquery>

<partialquery name="item::get_id.gi_get_item_id_3">
	<querytext>
	)
	</querytext>
</partialquery>

<partialquery name="item::get_revision_content.grc_get_all_content_1">
	<querytext>

	, content__blob_to_string(content) as text

	</querytext>
</partialquery>

</queryset>