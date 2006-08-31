<?xml version="1.0"?>
<queryset>

<fullquery name="get_content_items">      
      <querytext>

	select * from cr_revisions r join cr_item_template_map itm on (r.item_id = itm.item_id) 
         where itm.template_id = :template_id
           and r.revision_id = content_item__get_best_revision(r.item_id)

      </querytext>
</fullquery>

</queryset>
