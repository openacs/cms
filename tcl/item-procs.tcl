##########################################
#
# Procs for accessing content item properties

# @namespace item
#
# The item commands allow easy access to properties of the
# content_item object. In the future, a unified API for caching
# item properties will be developed here.

# @see namespace publish

namespace eval item {}

# @public get_live_revision
#
# Retrieves the live revision for the item. If the item has no live
# revision, returns an empty string.
#
# @param  item_id   The item id
#
# @return The live revision id for the item, or an empty string if no
#         live revision exists
# @see proc item::get_best_revision 
# @see proc item::get_item_from_revision

ad_proc item::get_live_revision { item_id } {

  template::query glr_get_live_revision live_revision onevalue "
    select live_revision from cr_items
      where item_id = :item_id" -cache "item_live_revision $item_id"

  if { [template::util::is_nil live_revision] } {
    ns_log notice "WARNING: No live revision for item $item_id"
    return ""
  } else {
    return $live_revision
  }
}



# @public get_best_revision
#
# Attempts to retrieve the live revision for the item. If no live revision
# exists, attempts to retrieve the latest revision. If the item has no
# revisions, returns an empty string.
#
# @param  item_id   The item id
#
# @return The best revision id for the item, or an empty string if no
#         revisions exist
# @see proc item::get_live_revision 
# @see proc item::get_item_from_revision

ad_proc item::get_best_revision { item_id } {
  template::query gbr_get_best_revision revision_id onevalue "
    select content_item.get_best_revision(:item_id) from dual
  " -cache "item_best_revision $item_id"

  return $revision_id
}


# @public get_item_from_revision
#
# Gets the item_id of the item to which the revision belongs.
#
# @param  revision_id   The revision id
#
# @return The item_id of the item to which this revision belongs
# @see proc item::get_live_revision 
# @see proc item::get_best_revision

ad_proc item::get_item_from_revision { revision_id } {
  template::query gifr_get_one_revision item_id onevalue "
    select item_id from cr_revisions where revision_id = :revision_id
  " -cache "item_from_revision $revision_id"
  return $item_id
}


# @public get_url
#
# Retrieves the relative URL stub to th item. The URL is relative to the
# page root, and has no extension (Example: "/foo/bar/baz"). 
#
# @param  item_id   The item id
#
# @return The relative URL to the item, or an empty string on failure
# @see proc item::get_extended_url

ad_proc item::get_url { item_id } {

  # Get the path
  template::query gu_get_path item_path onevalue "
    select content_item.get_path(:item_id) from dual
  " -cache "item_path $item_id" 

  if { [info exists item_path] } {
    return $item_path
  } else {
    return ""
  }
}

# @public get_id
#
# Looks up the URL and gets the item id at that URL, if any.
#
# @param  url           The URL
# @param  root_folder   {default The Sitemap}
#   The ID of the root folder to use for resolving the URL
#
# @return The item ID of the item at that URL, or the empty string
#   on failure
# @see proc item::get_url

ad_proc item::get_id { url {root_folder ""}} {

  # Strip off file extension
  set last [string last "." $url]
  if { $last > 0 } {
    set url [string range $url 0 [expr $last - 1]]
  }
  # FIX ME
  set sql [db_map gi_get_item_id_1] "select content_item.get_id(:url"
  if { ![template::util::is_nil root_folder] } {
      append sql [db_map gi_get_item_id_2] ", :root_folder"
  } 
  append sql [db_map gi_get_item_id_3] ") from dual"

  # Get the path
  template::query gi_get_item_id item_id onevalue $sql -cache "item_id $url $root_folder" 

  if { [info exists item_id] } {
    return $item_id
  } else {
    return ""
  }
}

# @public get_mime_info
#
# Creates a onerow datasource in the calling frame which holds the
# mime_type and file_extension of the specified revision. If the
# revision does not exist, does not create the datasource.
#
# @param  revision_id     The revision id
# @param  datasource_ref  {default mime_info} The name of the
#   datasource to be created. The datasource  will have two columns, 
#   mime_type and file_extension.
#
# return    1 (one) if the revision exists, 0 (zero) otherwise.
# @see proc item::get_extended_url

ad_proc item::get_mime_info { revision_id {datasource_ref mime_info} } {

  return [template::query gmi_get_mime_info mime_info onerow "
    select 
      m.mime_type, m.file_extension
    from
      cr_mime_types m, cr_revisions r
    where
      r.mime_type = m.mime_type
    and
      r.revision_id = :revision_id
  " -cache "rev_mime_info $revision_id" -uplevel]
}


# @public get_content_type
#
# Retrieves the content type of tyhe item. If the item does not exist,
# returns an empty string.
#
# @param  item_id   The item id
#
# @return The content type of the item, or an empty string if no such
#         item exists

ad_proc item::get_content_type { item_id } {

  template::query gct_get_content_type content_type onevalue "
    select content_type from cr_items where
      item_id = :item_id
  " -cache "item_content_type $item_id"

  if { [info exists content_type] } {
    return $content_type
  } else {
    return ""
  }
}

# @public get_content_type
#
# Retrieves the relative URL of the item with a file extension based
# on the item's mime_type (Example: "/foo/bar/baz.html"). 
#
# @param  item_id   The item id
#
# @option template_extension   Signifies that the file extension should
#     be retrieved using the mime_type of the template assigned to
#     the item, not from the item itself. The live revision of the
#     template is used. If there is no template which could be used to
#     render the item, or if the template has no live revision, the
#     extension defaults to ".html"
#
# @option revision_id {default the live revision} Specifies the
#     revision_id which will be used to retrieve the item's mime_type.
#     This option is ignored if the -template_extension 
#     option is specified.
#
# @return The relative URL of the item with the appropriate file extension
#         or an empty string on failure
# @see proc item::get_url
# @see proc item::get_mime_info
# @see proc item::get_template_id

ad_proc item::get_extended_url { item_id args } {

  set item_url [get_url $item_id]

  if { [template::util::is_nil item_url] } {
    ns_log notice "WARNING: No item URL found for content item $item_id"
    return ""
  }

  template::util::get_opts $args

  # Get full path
  set file_url [ns_normalizepath "/$item_url"]

  # Determine file extension
  if { [info exists opts(template_extension)] } {

    set file_extension "html"

    # Use template mime type
    set template_id [get_template_id $item_id]

    if { ![template::util::is_nil template_id] } {
      # Get extension from the template mime type 
      set template_revision_id [get_best_revision $template_id]

      if { ![template::util::is_nil template_revision_id] } {
        get_mime_info $template_revision_id mime_info   

        if { [info exists mime_info] } {
          set file_extension $mime_info(file_extension)
        }
      }

    }
  } else {
    # Use item mime type if template extension does not exist

    # Determine live revision, if none specified
    if { [template::util::is_nil opts(revision_id)] } {
      set revision_id [get_live_revision $item_id]

      if { [template::util::is_nil revision_id] } {
	ns_log notice "WARNING: No live revision for content item $item_id"
	return ""
      }

    } else {
      set revision_id $opts(revision_id)
    }

    get_mime_info $revision_id mime_info   
    set file_extension $mime_info(file_extension)
  }

  append file_url ".$file_extension"
   
  return $file_url
} 

# @public get_template_id
#
# Retrieves the template which can be used to render the item. If there is
# a template registered directly to the item, returns the id of that template.
# Otherwise, returns the id of the default template registered to the item's
# content_type. Returns an empty string on failure.
#
# @param  item_id   The item id
# @param  context   {default 'public'} The context in which the template 
#  will be used.
#
# @return The template_id of the template which can be used to render the
#   item, or an empty string on failure
#
# @see proc item::get_template_url

ad_proc item::get_template_id { item_id {context public} } {

  template::query gti_get_template_id template_id onevalue "
    select content_item.get_template(:item_id, :context) as template_id
    from dual" -cache "item_itemplate_id $item_id"

  if { [info exists template_id] } {
    return $template_id
  } else {
    return ""
  }
}

# @public get_template_url
#
# Retrieves the relative URL of the template which can be used to
# render the item. The URL is relative to the TemplateRoot as it is
# specified in the ini file.
#
# @param  item_id   The item id
# @param  context   {default 'public'} The context in which 
#   the template will be used.
#
# @return The template_id of the template which can be used to render the
#   item, or an empty string on failure
#
# @see proc item::get_template_id

ad_proc item::get_template_url { item_id {context public} } {

  set template_id [get_template_id $item_id $context]

  if { [template::util::is_nil template_id] } {
    return ""
  }

  return [get_url $template_id]
}
  
# @public content_is_null
#
# Determines if the content for the revision is null (not mereley
# zero-length)
# @param revision_id The revision id
#
# @return 1 if the content is null, 0 otherwise

ad_proc item::content_is_null { revision_id } {
  template::query cin_get_content content_test onevalue "
    select 't' from cr_revisions 
      where revision_id = :revision_id
      and content is not null"
  return [template::util::is_nil content_test]
}

# @public content_methods_by_type
#
# Determines all the valid content methods for instantiating 
# a content type.
# Possible choices are text_entry, file_upload, no_content and 
# xml_import. Currently, this proc merely removes the text_entry
# method if the item does not have a text mime type registered to
# it. In the future, a more sophisticated mechanism will be
# implemented.
#
# @param   content_type  The content type
#  
# @option  get_labels    Return not just a list of types,
#   but a list of name-value pairs, as in the -options
#   ATS switch for form widgets 
#
# @return A TCL list of all possible content methods

ad_proc item::content_methods_by_type { content_type args } {
  
  template::util::get_opts $args

  template::query cmbt_get_content_mime_types types onelist "
    select mime_type from cr_content_mime_type_map
      where content_type = :content_type
      and lower(mime_type) like 'text/%'
  " -cache "content_mime_types $content_type"

  set need_text [expr [llength $types] > 0]

  if { [info exists opts(get_labels)] } {
    set methods [list \
      [list "No Content" no_content] \
      [list "File Upload" file_upload]]

    if { $need_text } {
      lappend methods [list "Text Entry" text_entry]
    } 

    lappend methods [list "XML Import" xml_import]
  } else {
    set methods [list no_content file_upload]
    if { $need_text } {
      lappend methods text_entry
    } 
    lappend methods xml_import
  }

  return $methods
}

# @public get_revision_content
#
# Create a onerow datasource called content in the calling frame
# which contains all attributes for the revision (including inherited
# ones).<p>
# The datasource will contain a column called "text", representing the
# main content (blob) of the revision, but only if the revision has a
# textual mime-type.
#
# @param revision_id The revision whose attributes are to be retrieved
#
# @option item_id  {default <i>auto-generated</i>} The item_id of the
#   corresponding item.
#
# @return 1 on success (and create a content array in the calling frame),
#   0 on failure 
#
# @see proc item::get_mime_info 
# @see proc item::get_content_type

ad_proc item::get_revision_content { revision_id args } {

  template::util::get_opts $args
 
  if { [template::util::is_nil opts(item_id)] } {
    # Get the item id
    set item_id [get_item_from_revision $revision_id]

    if { [template::util::is_nil item_id] } {
      ns_log notice "No such revision: $reivision_id"
      return 0
    }  
  } else {
    set item_id $opts(item_id)
  }

  # Get the mime type, decide if we want the text
  get_mime_info $revision_id
  # FIX ME
  if { [string equal \
           [lindex [split $mime_info(mime_type) "/"] 0] "text"] } {
      set text_sql [db_map grc_get_all_content_1] ",\n    content.blob_to_string(content) as text"
  } else {
    set text_sql ""
  }
 
  # Get the content type
  set content_type [get_content_type $item_id]

  # Get the table name
  template::query grc_get_table_names table_name onevalue "
    select table_name from acs_object_types 
    where object_type = :content_type
  " -cache "type_table_name $content_type" -persistent \
    -timeout 3600

  # Get (all) the content (note this is really dependent on file type)
  template::query grc_get_all_content content onerow "select 
    x.*, 
    :item_id as item_id $text_sql, 
    :content_type as content_type
  from
    cr_revisions r, ${table_name}x x
  where
    r.revision_id = :revision_id
  and 
    x.revision_id = r.revision_id
  " -cache "content_for_revision $revision_id" -persistent \
    -timeout 3600

  upvar content content

  if { ![array exists content] } { 
    ns_log Notice "No data found for item $item_id, revision $revision_id"
    return 0
  }
  
  return 1

}
  

# @public is_publishable
#
# Determine if the item is publishable. The item is publishable only
# if:
# <ul>
#  <li>All child relations, as well as item relations, are satisfied
#    (according to min_n and max_n)</li>
#  <li>The workflow (if any) for the item is finished</li>
# </ul>
#
# @param  item_id   The item id
#
# @return    1 if the item is publishable, 0 otherwise

ad_proc item::is_publishable { item_id } {
  template::query ip_is_publishable_p is_publishable onevalue "
    select content_item.is_publishable(:item_id) from dual
  " -cache "item_is_publishable $item_id"

  return [string equal $is_publishable t]
} 

# @public get_publish_status
#
# Get the publish status of the item. The publish status will be one of
# the following: 
# <ul>
#   <li><tt>production</tt> - The item is still in production. The workflow
#     (if any) is not finished, and the item has no live revision.</li>
#   <li><tt>ready</tt> - The item is ready for publishing</li> 
#   <li><tt>live</tt> - The item has been published</li>
#   <li><tt>expired</tt> - The item has been published in the past, but 
#    its publication has expired</li>
# </ul>
#
# @param item_id The item id
#
# @return The publish status of the item, or the empty string on failure
#
# @see proc item::is_publishable

ad_proc item::get_publish_status { item_id } {
  template::query gps_get_publish_status publish_status onevalue "
    select publish_status from cr_items where item_id = :item_id
  " -cache "item_publish_status $item_id"

  return $publish_status
}

# @public get_title
#
# Get the title for the item. If a live revision for the item exists,
# use the live revision. Otherwise, use the latest revision.
#
# @param item_id The item id
#
# @return The title of the item
#
# @see proc item::get_best_revision

ad_proc item::get_title { item_id } {
  template::query gt_get_title title onevalue "
    select content_item.get_title(:item_id) from dual
  " -cache "item_title $item_id"

  return $title
}
