<?xml version="1.0"?>

<queryset>

	<fullquery name="cms::image::get.select_image">
		<querytext>
			select * from images i join cr_revisions r on (i.image_id = r.revision_id) 
                               join cr_items it on (r.item_id = it.item_id)
                         where i.image_id = :revision_id 
		</querytext>
	</fullquery>

</queryset>
