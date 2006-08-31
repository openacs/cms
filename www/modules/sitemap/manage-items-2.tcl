ad_page_contract {
    Manage Items

    @author Michael Steigman
    @creation-date March 2006
} {
    { folder_id:integer }
    { item_id:multiple }
    { action }
    { mount_point }
    { return_url }
}

# check perms, call the right procs and record results
set item_id_list $item_id
set errors [list]
set actions_completed 0
foreach item_id $item_id_list {
    set content_type [content::item::content_type -item_id $item_id]
    switch $action {
	move - copy {
	    if { [lsearch [cms::folder::get_registered_types $folder_id list] $content_type] > -1 } {
		if { [ catch {
		    switch $content_type {
			content_symlink {
			    if { $action eq "copy" } {
				content::symlink::copy -target_folder_id $folder_id -symlink_id $item_id
			    } else {
				lappend errors "Content symlinks cannot be moved."
				continue
			    }
			}
			content_template {
			    if { $action eq "move" } {
				cms::template::move -target_folder_id $folder_id -template_id $item_id
				content::item::move -target_folder_id $folder_id -item_id $item_id
			    } else {
				content::item::copy -target_folder_id $folder_id -item_id $item_id
			    }
			}
			default {
			    content::item::${action} -target_folder_id $folder_id -item_id $item_id
			} 
		    }
		} err ] } {
		    lappend errors $err
		} else {
		    incr actions_completed
		}
	    } else {
		lappend errors "Items of type [cms::type::pretty_name -content_type $content_type] are not allowed in this folder."
	    }
	}
	link {
	    if { [cms::folder::symlinks_allowed_p -folder_id $folder_id] } {
		if { [ catch { content::symlink::new -target_id $item_id -parent_id $folder_id } err ] } {
		    lappend errors $err
		} else {
		    incr actions_completed
		}
	    } else {
		lappend errors "Content symlinks are not allowed in this folder."
	    }
	}
	delete {
	    if { [ catch { 
		switch $content_type {
		    content_symlink {
			content::symlink::delete -symlink_id $item_id
		    }
		    content_template {
			cms::template::delete -template_id $item_id
			content::template::delete -template_id $item_id
		    }
		    content_folder {
			if { [content::folder::is_empty -folder_id $item_id] } {
			    content::folder::delete -folder_id $item_id
			} else {
			    lappend errors "Folders must be empty before they can be deleted."
			    continue
			}
		    }
		    default {
			content::item::delete -item_id $item_id
		    }  
		} 
	    } err ] } {
		lappend errors $err
	    } else {
		incr actions_completed

		# remove item from clipboard, if nec.
		set new_clip [cms::clipboard::remove_item [cms::clipboard::parse_cookie] $mount_point $item_id]
		ad_set_cookie content_marks [cms::clipboard::reassemble_cookie $new_clip]
		cms::clipboard::free $new_clip
	    }
	}
    }
}

if { [llength $errors] > 0 && $actions_completed > 0 } {
    # stay in target folder but notify user
    set errors [linsert $errors 0 "Some actions were completed but there were some problems with your request(s):"]
    foreach error $errors {
	util_user_message -message $error
    }
    ad_returnredirect [export_vars -base ../${mount_point}/index { folder_id }]
    ad_script_abort
} elseif { [llength $errors] > 0 } {
    set errors [linsert $errors 0 "There were problems with your request(s):"]
    foreach error $errors {
	util_user_message -message $error
    }
    # nothing done so redirect back to original folder and notify
    ad_returnredirect [export_vars -base ../${mount_point}/index { folder_id }]
    ad_script_abort
} else {
    ad_returnredirect [export_vars -base ../${mount_point}/index { folder_id }]
    ad_script_abort
}
