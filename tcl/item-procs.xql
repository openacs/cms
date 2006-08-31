<?xml version="1.0"?>
<queryset>

	<fullquery name="cms::item::get_id_from_revision.get_id">
		<querytext>
			select item_id from cr_revisions where revision_id = :revision_id
		</querytext>
	</fullquery>

	<fullquery name="cms::item::has_text_content_p.get_content_length">
		<querytext>
			select coalesce(char_length(content),0)
			  from cr_revisions
			 where revision_id = :revision_id
		</querytext>
	</fullquery>

	<fullquery name="cms::item::storage_type.get_storage_type">
		<querytext>
			select i.storage_type
			  from cr_items i join cr_revisions r on (i.item_id = r.item_id)
			 where r.revision_id = :revision_id
		</querytext>
	</fullquery>

	<fullquery name="cms::item::mime_type.get_mime_type">
		<querytext>
			select mime_type from cr_revisions where revision_id = :revision_id
		</querytext>
	</fullquery>

</queryset>

