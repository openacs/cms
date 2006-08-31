<?xml version="1.0"?>

<queryset>

	<fullquery name="cms::folder::get.select_folder">
		<querytext>
			select * from cr_folders f join cr_items i on (f.folder_id = i.item_id)
                         where f.folder_id = :folder_id 
		</querytext>
	</fullquery>
	<fullquery name="cms::folder::get_registered_types.get_types_list_of_lists">
		<querytext>
			select o.pretty_name, m.content_type
			  from acs_object_types o join cr_folder_type_map m on (m.content_type = o.object_type)
                         where m.folder_id = :folder_id
			   and content_item__is_subclass(o.object_type, 'content_revision') = 't'
			 order by case when o.object_type = 'content_revision' then '----' else o.pretty_name end
		</querytext>
	</fullquery>
	<fullquery name="cms::folder::get_registered_types.get_types_list">
		<querytext>
			select m.content_type
			  from cr_folder_type_map m
                         where m.folder_id = :folder_id
			 order by content_type
		</querytext>
	</fullquery>
	<fullquery name="cms::folder::symlinks_allowed_p.symlinks_allowed_p">
		<querytext>
			select 1 where exists (
			       select * from cr_folder_type_map m
				where m.folder_id = :folder_id
				  and content_type = 'content_symlink'
				)
		</querytext>
	</fullquery>

</queryset>
