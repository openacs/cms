<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="item::get_best_revision.gbr_get_best_revision">      
      <querytext>
      
    select content_item.get_best_revision(:item_id) from dual
  
      </querytext>
</fullquery>

 
<fullquery name="item::get_url.gu_get_path">      
      <querytext>
      
    select content_item.get_path(:item_id) from dual
  
      </querytext>
</fullquery>

 
<fullquery name="item::get_template_id.gti_get_template_id">      
      <querytext>
      
    select content_item.get_template(:item_id, :context) as template_id
    from dual
      </querytext>
</fullquery>

 
<fullquery name="item::is_publishable.ip_is_publishable_p">      
      <querytext>
      
    select content_item.is_publishable(:item_id) from dual
  
      </querytext>
</fullquery>

 
<fullquery name="item::get_title.gt_get_title">      
      <querytext>
      
    select content_item.get_title(:item_id) from dual
  
      </querytext>
</fullquery>

<fullquery name="item::get_id.id_get_item_id">      
      <querytext>
      select content_item__get_id(:url $root_sql) from dual
  
      </querytext>
</fullquery>

<partialquery name="item::get_revision_content.grc_get_all_content_1">
	<querytext>

	, content.blob_to_string(content) as text

	</querytext>
</partialquery>

</queryset>
