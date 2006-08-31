<?xml version="1.0"?>

<queryset>

	<fullquery name="cms::template::get.select_template">
		<querytext>
			select * from cr_templates t join cr_revisions r on (t.template_id = r.item_id) 
                               join cr_items i on (r.item_id = i.item_id)
                         where t.template_id = :template_id 
		           and r.revision_id = :revision_id
		</querytext>
	</fullquery>

	<fullquery name="cms::template::mime_type_options.get_mime_types">      
		<querytext>
			select label, m.mime_type from cr_mime_types m, cr_content_mime_type_map t
			 where t.content_type = 'content_template' and t.mime_type = m.mime_type
		</querytext>
	</fullquery>

</queryset>