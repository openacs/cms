ad_page_contract {
    List contents of a folder
    List path of this folder
    List path of any symlinks to this folder


    @author Michael Steigman
    @creation-date March 2006
} {
    { folder_id:integer }
    { list_action }
    { mount_point:optional "sitemap" }
    { return_url }
}

cms::folder::get -folder_id $folder_id
switch $list_action {
    move {
	set action_title "Move Items"
	set title "Move Items to $folder_info(label)"
    }
    copy {
	set action_title "Copy Items"
	set title "Copy Items to $folder_info(label)"
    }
    link {
	set action_title "Link Items"
	set title "Link Items to $folder_info(label)"
    }
    delete { 
	set action_title "Delete Items"
	set title "Delete Items"
    }
}

set root_id [cm::modules::${mount_point}::getRootFolderID [ad_conn subsite_id]]
set user_id [auth::require_login]
permission::require_permission -party_id $user_id -object_id $folder_id -privilege write

set clip [cms::clipboard::parse_cookie]
set clip_items [cms::clipboard::get_items $clip $mount_point]
set clip_length [llength $clip_items]
if { $clip_length == 0 } {
    set no_items_on_clipboard "t"
    ad_returnredirect -message "No items on the clipboard. Mark items and then choose \"$action_title\" again." $return_url
    ad_script_abort
} else {
    set no_items_on_clipboard "f"
}

template::list::create \
    -name marked_items \
    -multirow marked_items \
    -key item_id \
    -bulk_actions [list	"$action_title" \
		       "[export_vars -base manage-items-2 {mount_point list_action folder_id}]" \
		       "$title" \
		       "Cancel" \
		       "$return_url" \
		       "Cancel action and return to previous page"] \
    -bulk_action_export_vars { folder_id list_action mount_point return_url } \
    -elements {
	title {
	    label "Title"
	    link_url_col item_url
	}
	content_type {
	    label "Content Type"
	}
	path {
	    label "URL"
	}
    }

# get relevant marked items
db_multirow -extend { item_url content_type } -unclobber marked_items get_marked {} {
    set content_type [content::item::content_type -item_id $item_id]
    switch $content_type {
	content_folder {
	    set folder_id $item_id
	    set item_url [export_vars -base ../${mount_point}/index { folder_id }]
	}
	content_template {
	    set item_url [export_vars -base ../${mount_point}/properties { item_id }]
	}
	default {
	    set item_url [export_vars -base ../items/index { item_id }]
	}
    }
}
