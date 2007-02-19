ad_page_contract {
    Display a list of items on the clipboard

    @author Michael Steigman
    @creation-date March 2006
} {
    { id ""}
    { parent_id:integer ""}
    { mount_point:optional "clipboard" }
    { clip_tab "main"}
}

set user_id [auth::require_login]
set package_url [ad_conn package_url]
set clipboardfloats_p [cms::clipboard::ui::floats_p]

# set heads [ad_conn headers]
# for { set i 0 } { $i < [ns_set size $heads] } { incr i } {
#   ns_log debug "clipboard/index.tcl: [ns_set key $heads $i] = [ns_set value $heads $i]"
# }

# using the tabs to set the page id;
# then making sure that the tabs display the correct page
if { $clip_tab eq "main" } {
    set id ""
} else {
    set id $clip_tab
}

# The cookie for the clipboard looks like this:
# mnt:id,id,id|mnt:id,id,id|mnt:id,id,id.
# i.e., %22%22%7Csitemap%3A1254%7Ctemplates%3A1337%2C1441%7Ctypes%3Acontent_revision
# where %3A = : and %7C = |
set clip [cms::clipboard::parse_cookie]
set total_items [cms::clipboard::get_total_items $clip]
set total_items_string [ad_decode $total_items 1 "is a total of 1 item" \
			    "are a total of $total_items items"]
if { $id ne "" } {
    
    template::list::create \
	-name marked_items \
	-multirow marked_items \
	-key item_id \
	-no_data "No items of this type on the clipboard" \
	-bulk_actions [list "Remove" \
			   "remove-items" \
			   "Remove checked types from the clipboard"] \
	-bulk_action_export_vars {mount_point clip_tab} \
	-elements {
	    title {
		label "Title"
		display_template { @marked_items.title;noquote@ }
		link_url_col item_url
	    }
	    type {
		label "Type"
	    }
	    path {
		label "URL"
	    }
	}
    
    template::multirow create marked_items item_id title type path item_url
    set content_root [cm::modules::sitemap::getRootFolderID [ad_conn subsite_id]]
    set template_root [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]
    set item_list [cms::clipboard::get_items $clip $id]    

    foreach item $item_list {
	switch $id {
	    sitemap - templates {
		set title [content::item::get_title -item_id $item]
		set type [content::item::content_type -item_id $item]
		switch $type {
		    content_folder {
			set base_url "../${id}/index"
			set item_var folder_id
			set path "/[content::item::get_path -item_id $item -root_folder_id $content_root]"
		    }
		    content_template {
			set base_url "../templates/properties"
			set item_var item_id
			set path "/[content::item::get_path -item_id $item -root_folder_id $template_root]"
		    }
		    default {
			set base_url "../items/index"
			set item_var item_id
			set path "/[content::item::get_path -item_id $item -root_folder_id $content_root]"
		    }
		}		
	    }
	    types {
		set title [cms::type::pretty_name -content_type $item]
		set type "$item"
		set path "N/A"
		set base_url "../types/index"
		set item_var content_type
	    }
	    categories {
		set title [content::keyword::get_heading -keyword_id $item]
		set type "keyword"
		set path "N/A"
		set base_url "../categories/index"
		set item_var id
	    }
	}
	set $item_var $item
	set item_url [export_vars -base $base_url $item_var ]
	template::multirow append marked_items $item $title $type $path $item_url
    }
}

cms::clipboard::free $clip
