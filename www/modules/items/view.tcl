ad_page_contract {

    View attributes and content

} {
    {item_id:integer}
    {revision_id:integer}
}

# stuff the user doesn't need to see -
#  the globs in string match below are pretty safe
#  but globs on these columns could exclude custom attributes
set ignore_attributes [list \
			   object_title \
			   object_type \
			   security_inherit_p \
			   tree_sortkey \
			   max_child_sortkey
		       ]

switch [content::item::get_content_type -item_id $item_id] {
    content_template {
	cms::template::get -template_id $item_id -array_name info
    }
    default {
	content::item::get -item_id $item_id -revision latest -array_name info
    }
}

# maybe add path?
multirow create attributes attribute value
foreach attribute [lsort [array names info]] {
    if { [lsearch $ignore_attributes $attribute] == -1 && 
	 ![string match "*_id" $attribute] &&
	 ![string match "modifying_*" $attribute] &&
	 ![string match "*_revision" $attribute] &&
	 ![string match "content" $attribute] &&
	 ![string match "creation_*" $attribute] } {
	switch $attribute {
	    last_modified - publish_date {
		set value [lc_time_fmt $info($attribute) "%q %X"]
	    }
	    default {
		set value $info($attribute)
	    }
	}
	multirow append attributes $attribute $value
    }
}

# set some options for content viewing
if { [cms::item::storage_type -revision_id $revision_id] eq "text" } {
    if { [cms::item::has_text_content_p -revision_id $revision_id] } {
        set content_method text_entry
    } else {
        set content_method no_content
    }
} else {
    set content_method file_upload
}

set content_p 1
switch $content_method {
    text_entry {
	set content [content::get_content_value $revision_id]
    }
    file_upload {
	set mime_type [cms::item::mime_type -revision_id $revision_id] 
	set download_url [export_vars -base content-download {item_id revision_id}]
	if { [string match "image/*" $mime_type] } {
	    set file_type image
	} else {
	    set file_type file
	}
    }
    no_content {
	set content_p 0
    }
}
