	# if the item is or is linked to a content_folder, then 
	#   use the sitemap module to browse the folder
	set sql "select parent_id, 
                 content_folder.is_folder(item_id) as folder_p
                 from cr_items
                 where item_id = :resolved_id"

	query folder_check onerow $sql

	if { [info exists folder_check] } {
	    set folder_p $folder_check(folder_p)
	    set parent_id $folder_check(context_id)

	    if { [string equal $folder_p "t"] } {
		template::forward "../sitemap/index?id=$resolved_id&parent_id=$parent_id"
	    }
	}
    }
