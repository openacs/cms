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


ad_proc -public item::get_live_revision { item_id } {

  @public get_live_revision
 
  Retrieves the live revision for the item. If the item has no live
  revision, returns an empty string.
 
  @param  item_id   The item id
 
  @return The live revision id for the item, or an empty string if no
          live revision exists
  @see proc item::get_best_revision 
  @see proc item::get_item_from_revision

} {

    set live_revision [db_string glr_get_live_revision "" -default ""]

    if { [template::util::is_nil live_revision] } {
        ns_log notice "WARNING: No live revision for item $item_id"
        return ""
    } else {
        return $live_revision
    }
}


ad_proc -public item::get_item_from_revision { revision_id } {

  @public get_item_from_revision
 
  Gets the item_id of the item to which the revision belongs.
 
  @param  revision_id   The revision id
 
  @return The item_id of the item to which this revision belongs
  @see proc item::get_live_revision 
  @see proc item::get_best_revision

} {
    set item_id [db_string gifr_get_one_revision ""]
    return $item_id
}


ad_proc -public item::get_id { url {root_folder ""}} {

  @public get_id
 
  Looks up the URL and gets the item id at that URL, if any.
 
  @param  url           The URL
  @param  root_folder   {default The Sitemap}
    The ID of the root folder to use for resolving the URL
 
  @return The item ID of the item at that URL, or the empty string
    on failure
  @see proc item::get_url

} {

  # Strip off file extension
  set last [string last "." $url]
  if { $last > 0 } {
    set url [string range $url 0 [expr $last - 1]]
  }

  if { ![template::util::is_nil root_folder] } {
    set root_sql ", :root_folder, 'f'"
  } else {
    set root_sql ", null, 'f'"
  }

  # Get the path
  set item_id [db_string id_get_item_id ""]

  if { [info exists item_id] } {
    return $item_id
  } else {
    return ""
  }
}




ad_proc -public item::get_content_type { item_id } {

  @public get_content_type
 
  Retrieves the content type of tyhe item. If the item does not exist,
  returns an empty string.
 
  @param  item_id   The item id
 
  @return The content type of the item, or an empty string if no such
          item exists

} {

    set content_type [db_string gct_get_content_type ""]

    if { [info exists content_type] } {
        return $content_type
    } else {
        return ""
    }
}


ad_proc -public item::content_methods_by_type { content_type args } {

  @public content_methods_by_type
 
  Determines all the valid content methods for instantiating 
  a content type.
  Possible choices are text_entry, file_upload, no_content and 
  xml_import. Currently, this proc merely removes the text_entry
  method if the item does not have a text mime type registered to
  it. In the future, a more sophisticated mechanism will be
  implemented.
 
  @param   content_type  The content type
   
  @option  get_labels    Return not just a list of types,
    but a list of name-value pairs, as in the -options
    ATS switch for form widgets 
 
  @return A TCL list of all possible content methods

} {
  
  template::util::get_opts $args

  set types [db_list cmbt_get_content_mime_types ""]

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


ad_proc -public item::get_revision_content { revision_id args } {

  @public get_revision_content
 
  Create a onerow datasource called content in the calling frame
  which contains all attributes for the revision (including inherited
  ones).<p>
  The datasource will contain a column called "text", representing the
  main content (blob) of the revision, but only if the revision has a
  textual mime-type.
 
  @param revision_id The revision whose attributes are to be retrieved
 
  @option item_id  {default <i>auto-generated</i>} The item_id of the
    corresponding item.
 
  @return 1 on success (and create a content array in the calling frame),
    0 on failure 
 
  @see proc item::get_mime_info 
  @see proc item::get_content_type

} {

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

  if { [string equal \
           [lindex [split $mime_info(mime_type) "/"] 0] "text"] } {
      set text_sql [db_map grc_get_all_content_1]
  } else {
      set text_sql ""
  }
 
  # Get the content type
  set content_type [get_content_type $item_id]

  # Get the table name
  set table_name [db_string grc_get_table_names ""]

  # Get (all) the content (note this is really dependent on file type)
  db_0or1row grc_get_all_content "" -column_array content

  upvar content content

  if { ![array exists content] } { 
    ns_log Notice "No data found for item $item_id, revision $revision_id"
    return 0
  }
  
  return 1

}
  


ad_proc -public item::is_publishable { item_id } {

  @public is_publishable
 
  Determine if the item is publishable. The item is publishable only
  if:
  <ul>
   <li>All child relations, as well as item relations, are satisfied
     (according to min_n and max_n)</li>
   <li>The workflow (if any) for the item is finished</li>
  </ul>
 
  @param  item_id   The item id
 
  @return    1 if the item is publishable, 0 otherwise

} {
    set is_publishable [db_string ip_is_publishable_p ""]

    return [string equal $is_publishable t]
} 


ad_proc -public item::get_publish_status { item_id } {

  @public get_publish_status
 
  Get the publish status of the item. The publish status will be one of
  the following: 
  <ul>
    <li><tt>production</tt> - The item is still in production. The workflow
      (if any) is not finished, and the item has no live revision.</li>
    <li><tt>ready</tt> - The item is ready for publishing</li> 
    <li><tt>live</tt> - The item has been published</li>
    <li><tt>expired</tt> - The item has been published in the past, but 
     its publication has expired</li>
  </ul>
 
  @param item_id The item id
 
  @return The publish status of the item, or the empty string on failure
 
  @see proc item::is_publishable

} {

  set publish_status [db_string gps_get_publish_status ""]

  return $publish_status
}


ad_proc -public item::get_title { item_id } {

  @public get_title
 
  Get the title for the item. If a live revision for the item exists,
  use the live revision. Otherwise, use the latest revision.
 
  @param item_id The item id
 
  @return The title of the item
 
  @see proc item::get_best_revision

} {

    set title [db_string gt_get_title ""]

    return $title
}
