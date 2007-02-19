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
