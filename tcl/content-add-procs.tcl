# content-add-procs.tcl


# @namespace content_add

# Procedures regarding content methods

namespace eval content_add {}



# @public content_method_html

# Generates HTML stub for revision content method choices for a content item

# @author Michael Pih

# @param db A database handle
# @param content_type The content type of the item
# @param item_id The item id

ad_proc content_add::content_method_html { content_type item_id } {
    
    set content_method_html ""

    set target "revision-add-2?item_id=$item_id"

    template::query count_text_mime_types has_text_mime_type onevalue "
      select
        count(*)
      from
        cr_content_mime_type_map
      where
        mime_type like ('%text/%')
      and
        content_type = :content_type
    "

    template::query count_mime_types mime_type_count onevalue "
      select
        count(*)
      from
        cr_content_mime_type_map
      where
        content_type = :content_type
    " 

    if { $mime_type_count > 0 } {

	append content_method_html "Add revised content via \["

	if { $has_text_mime_type > 0 } {
	    append content_method_html "
	      <a href=\"$target&content_method=text_entry\">Text Entry</a> | "
	}

	append content_method_html "
	  <a href=\"$target&content_method=file_upload\">File Upload</a> | "

	if { $has_text_mime_type > 0 } {
	    append content_method_html "
	      <a href=\"revision-upload?item_id=$item_id&content_type=$content_type\">XML Import</a> | "
	}

	append content_method_html "
	  <a href=\"$target&content_method=no_content\">No Content</a> "

	append content_method_html " \]"
    } else {
	append content_method_html "
          \[<a href=\"$target&content_method=no_content\">Add</a>\]"
    }
    return $content_method_html
}

