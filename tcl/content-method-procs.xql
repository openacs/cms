<?xml version="1.0"?>
<queryset> 
	<fullquery name="count_text_mime_types">
		<querytext>
			select count(*)
			from cr_content_mime_type_map
			where mime_type like ('%text/%')
			 and content_type = :content_type
		</querytext>
	</fullquery>
</queryset>
