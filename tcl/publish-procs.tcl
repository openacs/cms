###############################################################
#
# @namespace publish
# 
# @author Stanislav Freidin
#
# The procs in this namespace are useful for publishing items,
# including items inside other items, and writing items to the
# filesystem. <p>
# Specifically, the <tt>content</tt>, <tt>child</tt> and
# <tt>relation</tt> tags are defined here.
#
# @see namespace item item.html

namespace eval publish {
  variable item_id_stack
  
  variable revision_html

  namespace eval handle {
    namespace eval text {}
    namespace eval program {}
    namespace eval image {}
  }
}  

###############################################
# Procs to maintain the item_id stack
# main_item_id is always the id at the top of the stack

# @private push_id
# 
# Push an item id on top of stack. This proc is used
# to store state between <tt>child</tt>, <tt>relation</tt>
# and <tt>content</tt> tags.
#
# @param item_id      
#   The id to be put on stack
#
# @param revision_id  {default ""} 
#    The id of the revision to use. If missing, live
#    revision will most likely be used
#
# @see proc publish::pop_id 
# @see proc publish::get_main_item_id
# @see proc publish::get_main_revision_id

proc publish::push_id { item_id {revision_id ""}} {
  variable item_id_stack 
  variable revision_html 

  if { [template::util::is_nil item_id] } {
    error "Null id pushed on stack in publish::push_id"
  }

  # Determine old configuration
  set old_item_id ""
  set old_revision_id ""

  if { [info exists ::content::item_id] } {
    set old_item_id $::content::item_id
  }
 
  if { [info exists ::content::revision_id] } {
    set old_revision_id $::content::revision_id
  }

  # Preserve old data
  if { ![template::util::is_nil old_item_id] } {

    set pair [list $old_item_id $old_revision_id]

    if { ![template::util::is_nil item_id_stack] } {
      set item_id_stack [concat [list $pair] $item_id_stack]
    } else {
      # This is the first id pushed - also clear the cache
      set item_id_stack [list $pair]
      array unset revision_html
    }
  } else {
    set item_id_stack [list]
  }

  # Set new data
  set ::content::item_id $item_id
  set ::content::revision_id $revision_id
}

# @private pop_id
#
# Pop the item_id and the revision_id off the top of the stack.
# Clear the temporary item cache if the stack becomes empty.
#
# @return The popped item id, or the empty string if the string is
#   already empty
#
# @see proc publish::push_id 
# @see proc publish::get_main_item_id
# @see proc publish::get_main_revision_id

proc publish::pop_id {} {
  variable item_id_stack 

  set pair [lindex $item_id_stack 0]
  if { [template::util::is_nil pair] } {
    #error "Item id stack is empty in publish::pop_id"
  }
 
  set item_id_stack [lrange $item_id_stack 1 end]

  # If the stack is now empty, clear the cache
  if { [template::util::is_nil item_id_stack] } {
    array unset revision_html
  }

  set ::content::item_id [lindex $pair 0]
  set ::content::revision_id [lindex $pair 1]

  return $::content::item_id
}

# @private get_main_item_id
#
# Get the main item id from the top of the stack
#
# @return the main item id
#
# @see proc publish::pop_id 
# @see proc publish::push_id 
# @see proc publish::get_main_revision_id

proc publish::get_main_item_id {} {

  if { ![template::util::is_nil ::content::item_id] } {
    set ret $::content::item_id
  } else {
    error "Item id stack is empty"
  }

  return $ret
}

# @private get_main_revision_id
#
# Get the main item revision from the top of the stack
#
# @return the main item id
#
# @see proc publish::pop_id 
# @see proc publish::push_id 
# @see proc publish::get_main_item_id

proc publish::get_main_revision_id {} {

  if { [template::util::is_nil ::content::revision_id] } {
    set item_id [get_main_item_id]
    set ret [item::get_live_revision $item_id]
  } else {
    set ret $::content::revision_id
  }

  return $ret
}

###################################################
#
# Publish procs

# @public get_page_root
#
# Get the page root. All items will be published to the 
# filesystem with their URLs relative to this root.
# The page root is controlled by the PageRoot parameter in CMS.
# A relative path is relative to [ns_info pageroot]
# The default is [ns_info pageroot]
#
# @return The page root
#
# @see proc publish::get_template_root
# @see proc publish::get_publish_roots

proc publish::get_page_root {} {

  set root_path [ad_parameter -package_id [ad_conn package_id] \
      PageRoot dummy ""]

  if { [string index $root_path 0] != "/" } {
    # Relative path, prepend server_root
    set root_path "[ns_info pageroot]/$root_path"
  }

  return [ns_normalizepath $root_path]

}

# @public get_publish_roots
#
# Get a list of all page roots to which files may be published.
# The publish roots are controlled by the PublishRoots parameter in CMS,
# which should be a space-separated list of all the roots. Relative paths
# are relative to publish::get_page_root.
# The default is [list [publish::get_page_root]]
#
# @return A list of all the publish roots
#
# @see proc publish::get_template_root
# @see proc publish::get_page_root
proc publish::get_publish_roots {} {

  set root_paths [ad_parameter -package_id [ad_conn package_id] \
      PublishRoots dummy]
  
  if { [llength $root_paths] == 0 } {
    set root_paths [list [get_page_root]]
  }

  # Resolve relative paths
  set page_root [publish::get_page_root]
  set absolute_paths [list]
  foreach path $root_paths {
    if { [string index $path 0] != "/" } {
      lappend absolute_paths [ns_normalizepath "$page_root/$path"]
    } else {
      lappend absolute_paths $path
    }
  }

  return $absolute_paths
}


# @public get_template_root
#
# Get the template root. All templates are assumed to exist
# in the filesystem with their URLs relative to this root.
# The page root is controlled by the TemplateRoot parameter in CMS.
# The default is /web/yourserver/templates
#
# @return The template root
#
# @see proc content::get_template_root, proc publish::get_page_root

proc publish::get_template_root {} {
  return [content::get_template_root]
}

# Legacy compatibility

proc content::get_template_path {} {
  return [publish::get_template_root]
}

# @public mkdirs
#
# Create all the directories neccessary to save the specified file
#
# @param path 
#    The path to the file that is about to be saved
#

proc publish::mkdirs { path } {

  set index [string last "/" $path]
  if { $index != -1 } {
    file mkdir [string range $path 0 [expr $index - 1]]
  } 
}

# @private foreach_publish_path
#
# Execute some TCL code for each root path in the PublishRoots
# parameter
#
# @param url       Relative URL to append to the roots
# @param code      Execute this code
# @param root_path {default The empty string}
#    Use this root path instead of the paths specified in the INI
#    file
# 
# @see proc publish::get_publish_roots

proc publish::foreach_publish_path { url code {root_path ""} } {
  if { ![template::util::is_nil root_path] } {
    set paths [list $root_path]
  } else {
    set paths [get_publish_roots]
  }

  upvar filename filename
  upvar current_page_root current_page_root

  foreach root_path $paths {
    set current_page_root $root_path
    set filename [ns_normalizepath "/$root_path/$url"]   
    uplevel $code
  }
}
    

# @private write_multiple_files 
#
# Write a relative URL to the multiple publishing roots.
#
# @param url   Relative URL of the file to write
# @param text  A string of text to be written to the URL
#
# @see proc template::util::write_file
# @see proc publish::get_publish_roots
# @see proc publish::write_multiple_blobs

proc publish::write_multiple_files { url text {root_path ""}} {
  foreach_publish_path $url {
    mkdirs $filename
    template::util::write_file $filename $text
    ns_chmod $filename 0764
    ns_log notice "PUBLISH: Wrote text to $filename"
  } $root_path
}

# @private write_multiple_blobs
#
# Write the content of some revision to multiple publishing roots.
# 
# @param db           A valid database handle
# @param url          Relative URL of the file to write
# @param revision_id  Write the blob for this revision 
#
# @see proc publish::get_publish_roots
# @see proc publish::write_multiple_files

proc publish::write_multiple_blobs { 
  db url revision_id {root_path ""} 
} {
  foreach_publish_path $url {
    mkdirs $filename
    ns_ora blob_get_file $db "
      select content from cr_revisions where revision_id = $revision_id
    " $filename
    ns_chmod $filename 0764
    ns_log notice "PUBLISH: Wrote revision $revision_id to $filename"
  } $root_path
}

# @private delete_multiple_files
#
# Delete the specified URL from the filesystem, for all revisions
# 
# @param url          Relative URL of the file to write
#
# @see proc publish::get_publish_roots
# @see proc publish::write_multiple_files
# @see proc publish::write_multiple_blobs
proc publish::delete_multiple_files { url {root_path ""}} {
  foreach_publish_path $url {
    ns_unlink -nocomplain $filename 
    ns_log notice "PUBLISH: Delete file $filename"
  } $root_path
}

# @public write_content
#
# Write the content (blob) of a revision into a binary file in the 
# filesystem. The file will be published at the relative URL under
# each publish root listed under the PublishRoots parameter in the 
# server's INI file (the value returnded by publish::get_page_root is
# used as the default). The file extension will be based on the
# revision's mime-type. <br>
# For example, an revision whose mime-type is "image/jpeg" 
# for an item at "Sitemap/foo/bar" may be written as 
# /web/your_server_name/www/foo/bar.jpg
#
# @param revision_id 
#   The id of the revision to write
#
# @option item_id   {default The item_id of the revision} 
#   Specifies the item  to which this revision belongs (mereley
#   for optimization purposes)
#
# @option text     
#   If specified, indicates that the content of the
#   revision is readable text (clob), not a binary file
#
# @option root_path {default All paths in the PublishPaths parameter}
#   Write the content to this path only.
#
# @return The relative URL of the file that was written, or an empty
#         string on failure
#
# @see proc content::get_content_value
# @see proc publish::get_publish_roots

proc publish::write_content { revision_id args } {

  template::util::get_opts $args

  if { [template::util::is_nil opts(root_path)] } {
    set root_path ""
  } else {
    set root_path $opts(root_path)
  }

  set db [template::begin_db_transaction]

  # Get the item id if none specified
  if { [template::util::is_nil opts(item_id)] } {
    set item_id [content_item::get_item_from_revision $revision_id]
    
    if { [template::util::is_nil item_id] } {
      ns_log notice \
        "WARNING: publish::write_content: No such revision $revision_id"
      template::end_db_transaction
      return ""
    }
  } else {
    set item_id $opts(item_id)
  }
  
  set file_url [item::get_extended_url $item_id -revision_id $revision_id]

  # Write blob/text to file
  ns_log notice "Writing item $item_id to $file_url"

  if { [info exists opts(text)] } {
    set text [content::get_content_value $revision_id]
    write_multiple_files $file_url $text $root_path
  } else {

    # Determine if the blob is null. If it is, give up (or else the
    # ns_ora blob_get_file will crash).
    if { [item::content_is_null $revision_id] } {
      ns_log notice \
       "WARNING: publish::write_content: No content supplied for revision $revision_id"
      return ""
    }

    # Write the blob
    write_multiple_blobs $db $file_url $revision_id $root_path
  }

  template::end_db_transaction

  # Return either the full path or the relative URL
  return $file_url
}


# @public get_html_body
#
# Strip the &lt;body&gt; tags from the HTML, leaving just the body itself.
# Useful for including templates in each other.
#
# @param html 
#   The html to be processed
#
# @return Everything between the &lt;body&gt; and the &lt;/body&gt; tags
#    if they exist; the unchanged HTML if they do not

proc publish::get_html_body { html } {
  
  if { [regexp -nocase {<body[^>]*>(.*)</body>} $html match body_text] } {
    return $body_text
  } else {
    return $html
  }
}

# @private render_subitem
#
# Render a child/related item and return the resulting HTML, stripping
# off the headers.
#
# @param main_item_id  The id of the parent item
#
# @param relation_type 
#   Either <tt>child</tt> or <tt>relation</tt>. 
#   Determines which tables are searched for subitems.
#
# @param relation_tag  
#  The relation tag to look for
#
# @param index         
#   The relative index of the subitem. The subitem with
#   lowest <tt>order_n</tt> has index 1, the second lowest <tt>order_n</tt>
#   has index 2, and so on.
#
# @param is_embed      
#   If "t", the child item may be embedded directly
#   in the HTML. Otherwise, it may be dynamically included. The proc
#   does not process this parameter directly, but passes it to
#   <tt>handle_item</tt>
#
# @param extra_args    
#   Any additional HTML arguments to be used when
#   rendering the item, in form {name value name value ...}
#
# @param is_merge {default t} 
#   If "t", <tt>merge_with_template</tt> may
#   be used to render the subitem. Otherwise, <tt>merge_with_template</tt>
#   should not be used, in order to prevent infinite recursion.
#
# @return The rendered HTML for the child item
#
# @see proc publish::merge_with_template
# @see proc publish::handle_item

proc publish::render_subitem { 
  main_item_id relation_type relation_tag \
  index is_embed extra_args {is_merge t}
} {

  # Get the child item

  if { [string equal $relation_type child] } {
    template::query subitems onelist "
      select 
        child_id
      from 
        cr_child_rels r, cr_items i
      where 
        r.parent_id = :main_item_id
      and 
        r.relation_tag = :relation_tag
      and
        i.item_id = r.child_id
      order by 
        order_n" -cache "item_child_items $main_item_id $relation_tag"
  } else {
    template::query subitems onelist "
      select 
        related_object_id
      from 
        cr_item_rels r, cr_items i
      where 
        r.item_id = :main_item_id
      and 
        r.relation_tag = :relation_tag
      and
        i.item_id = r.related_object_id 
      order by 
        r.order_n" -cache "item_related_items $main_item_id $relation_tag"  
  }

  set sub_item_id [lindex $subitems [expr $index - 1]]
   
  if { [template::util::is_nil sub_item_id] } {
    ns_log notice "No such subitem"
    return ""
  }

  # Call the appropriate handler function
  set code [list handle_item $sub_item_id -html $extra_args]

  if { [string equal $is_embed t] } {
    lappend code -embed
  }

  return [get_html_body [eval $code]]
}


# @public proc_exists
#
# Determine if a procedure exists in the given namespace
#
# @param namespace_name    The fully qualified namespace name,
#  such as "template::util"
#
# @param proc_name         The proc name, such as "is_nil"
#
# @return 1 if the proc exists in the given namespace, 0 otherwise

proc publish::proc_exists { namespace_name proc_name } {

  return [expr ![string equal \
                  [namespace eval $namespace_name \
                    "info procs $proc_name"] {}]]
}

# @public get_mime_handler
#
# Return the name of a proc that should be used to render items with
# the given mime-type.
# The mime type handlers should all follow the naming convention
#
# <blockquote>
# <tt>proc publish::handle::<i>mime_prefix</i>::<i>mime_suffix</i></tt>
# </blockquote>
#
# If the specific mime handler could not be found, <tt>get_mime_handler</tt>
# looks for a generic procedure with the name
#
# <blockquote>
# <tt>proc publish::handle::<i>mime_prefix</i></tt>
# </blockquote>
#
# If the generic mime handler does not exist either, 
# <tt>get_mime_handler</tt> returns ""
#
# @param mime_type 
#   The full mime type, such as "text/html" or "image/jpg"
#
# @return The name of the proc which should be used to handle the mime-type,
#  or an empty string on failure.
#
# @see proc publish::handle_item

proc publish::get_mime_handler { mime_type } {
  set mime_pair [split $mime_type "/"]
  set mime_prefix [lindex $mime_pair 0]
  set mime_suffix [lindex $mime_pair 1]

  # Look for the specific handler
  if { [proc_exists "::publish::handle::${mime_prefix}" $mime_suffix] } {
    return "::publish::handle::${mime_prefix}::$mime_suffix"
  }

  # Look for the generic handler
  if { [proc_exists "::publish::handle" $mime_prefix] } {
    return "::publish::handle::${mime_prefix}"
  }

  # Failure
  return ""
}


# @private handle_item
#
# Render an item either by looking it up in the the temporary cache,
# or by using the appropriate mime handler. Once the item is rendered, it 
# is stored in the temporary cache under a key which combines the item_id,
# any extra HTML parameters, and a flag which specifies whether the item
# was merged with its template. <br>
# This proc takes the same arguments as the individual mime handlers.
#
# @param item_id  The id of the item to be rendered
#
# @option revision_id {default The live revision}  
#   The revision which is to be used when rendering the item
#
# @option no_merge    
#   Indicates that the item should NOT be merged with its
#   template. This option is used to avoid infinite recursion.
#
# @option refresh     
#   Re-render the item even if it exists in the cache.
#   Use with caution - circular dependencies may cause infinite recursion
#   if this option is specified
#
# @option embed    
#    Signifies that the content should be statically embedded directly in
#    the HTML. If this option is not specified, the item may
#    be dynamically referenced, f.ex. using the <tt>&lt;include&gt;</tt>
#    tag
#
# @option html
#    Extra HTML parameters to be passed to the item handler, in format
#    {name value name value ...}
#
# @return The rendered HTML for the item, or an empty string on failure
#
# @see proc publish::handle_binary_file
# @see proc publish::handle::text
# @see proc publish::handle::image

proc publish::handle_item { item_id args } {

  template::util::get_opts $args

  variable revision_html

  # Process options
  if { [template::util::is_nil opts(revision_id)] } {
    set revision_id [item::get_live_revision $item_id]
  } else {
    set revision_id $opts(revision_id)
  }

  if { [template::util::is_nil revision_id] } {
    ns_log notice "HANDLER: No live revision for $item_id"
    return ""
  }

  if { [template::util::is_nil opts(no_merge)] } {
    set merge_str "merge"
  } else {
    set merge_str "no_merge"
  }

  # Create a unique key
  set revision_key "$merge_str $revision_id"
  if { ![template::util::is_nil opts(html)] } {
    lappend revision_key $opts(html)
  }

  # Pull the item out of the cache
  if { ![info exists opts(refresh)] && \
        [info exists revision_html($revision_key)] } {

    ns_log notice "HANDLER: Fetching $item_id from cache"
    return $revision_html($revision_key)

  } else {

    # Render the item and cache it
    ns_log notice "HANDLER: Rendering item $item_id"
    item::get_mime_info $revision_id mime_info
    set item_handler [get_mime_handler $mime_info(mime_type)]
  
    if { [template::util::is_nil item_handler] } {
      ns_log notice "HANDLER: No mime handler for mime type $mime_info(mime_type)"
      return ""
    }

    # Call the appropriate handler function
    set code [list $item_handler $item_id]
    set code [concat $code $args]

    # Pass the revision_id 
    if { ![info exists opts(revision_id)] } {
      lappend code -revision_id $revision_id
    }

    set html [eval $code]
    ns_log notice "HANDLER: Caching html for revision $revision_id"
    set revision_html($revision_key) $html
    
    return $html
  }
}


# @public publish_revision
#
# Render a revision for an item and write it to the filesystem. The
# revision is always rendered with the <tt>-embed</tt> option turned 
# on.
#
# @param revision_id  The revision id
#
# @option root_path {default All paths in the PublishPaths parameter}
#   Write the content to this path only.
#
# @see proc item::get_extended_url
# @see proc publish::get_publish_paths
# @see proc publish::handle_item

proc publish::publish_revision { revision_id args} {

  template::util::get_opts $args

  if { [template::util::is_nil opts(root_path)] } {
    set root_path ""
  } else {
    set root_path $opts(root_path)
  }

  # Get tem id
  set item_id [item::get_item_from_revision $revision_id]
  # Render the item
  set item_content [handle_item $item_id -revision_id $revision_id -embed]

  if { ![template::util::is_nil item_content] } {
    set item_url [item::get_extended_url $item_id \
       -revision_id $revision_id -template_extension]

    write_multiple_files $item_url $item_content $root_path
  }

}

# @public unpublish_item
#
# Delete files which were created by <tt>publish_revision</tt>
#
# @param item_id   The item id
#
# @option revision_id {default The live revision}  
#   The revision which is to be used for determining the item filename
#
# @option root_path {default All paths in the PublishPaths parameter}
#   Write the content to this path only.
#
# @see proc publish::publish_revision

proc publish::unpublish_item { item_id args } {
  
  template::util::get_opts $args

  if { [template::util::is_nil opts(root_path)] } {
    set root_path ""
  } else {
    set root_path $opts(root_path)
  }

  # Get revision id
  if { [template::util::is_nil opts(revision_id)] } {
    set revision_id [item::get_live_revision $item_id]
  } else {
    set revision_id $opts(revision_id)
  }
  
  # Delete the main file
  set item_url [item::get_extended_url $item_id -revision_id $revision_id]
  if { ![template::util::is_nil item_url] } {
    delete_multiple_files $item_url $root_path
  }

  # Delete the template's file
  set template_id [item::get_template_id $item_id]

  if { [template::util::is_nil template_id] } {
    return
  }

  set template_revision_id [item::get_best_revision $template_id]

  if { [template::util::is_nil template_revision_id] } {
    return
  }

  item::get_mime_info $template_revision_id mime_info   
  
  if { [info exists mime_info] } {
    set item_url [item::get_url $item_id]
    if { ![template::util::is_nil item_url] } {
      delete_multiple_files "${item_url}.$mime_info(file_extension)" $root_path
    }
  }

}

# @private merge_with_template
#
# Merge the item with its template and return the resulting HTML. This proc
# is simlar to <tt>content::init</tt>
#
# @param item_id   The item id
#
# @option revision_id {default The live revision}  
#   The revision which is to be used when rendering the item
#
# @option html
#   Extra HTML parameters to be passed to the ADP parser, in format
#   {name value name value ...}
#
# @return The rendered HTML, or the empty string on failure
#
# @see proc publish::handle_item

proc publish::merge_with_template { item_id args } { 
  #set ::content::item_id $item_id
  set ::content::item_url [item::get_url $item_id]

  template::util::get_opts $args

  # Either auto-get the live revision or use the parameter
  if { ![template::util::is_nil opts(revision_id)] } {
    set revision_id $opts(revision_id)
  } else {
    set revision_id [item::get_live_revision $item_id]
  }

  # Get the template 
  set ::content::template_url [item::get_template_url $item_id]    

  if { [string equal $::content::template_url {}] } { 
    ns_log notice "MERGE: No template for item $item_id"
    return "" 
  }

  ns_log notice "MERGE: Template for item $item_id is $::content::template_url"

  # Get the full path to the template
  set root_path [content::get_template_root]
  set file_stub [ns_normalizepath "$root_path/$::content::template_url"]

  # Set the passed-in variables
  if { ![template::util::is_nil opts(html)] } {
    set adp_args $opts(html)
  } else {
    set adp_args ""
  }

  # Parse the template and return the result
  publish::push_id $item_id $revision_id
  ns_log notice "MERGE: Parsing $file_stub"
  set html [eval "template::adp_parse \"$file_stub\" \[list $adp_args\]"]
  publish::pop_id

  return $html
}
  
# @private set_to_pairs
#
# Convert an ns_set into a list of name-value pairs, in form
# {name value name value ...}
#
# @param params   The ns_set id
# @param exclusion_list {}
#    A list of keys to be ignored
#
# @return A list of name-value pairs representing the data in the ns_set

proc publish::set_to_pairs { params {exclusion_list ""} } {

  set extra_args [list]
  for { set i 0 } { $i < [ns_set size $params] } { incr i } {
    set key   [ns_set key $params $i]
    set value [ns_set value $params $i]
    if { [lsearch $exclusion_list $key] == -1 } {
      lappend extra_args $key $value
    }
  }

  return $extra_args
}

#######################################################
#
# The content tags

# @private process_tag
#
# Process a <tt>child</tt> or <tt>relation</tt> tag. This is
# a helper proc for the tags, which acts as a wrapper for
# <tt>render_subitem</tt>.
#
# @param relation_type  Either <tt>child</tt> or <tt>relation</tt>
# @param params         The ns_set id for extra HTML parameters
#
# @see proc publish::render_subitem

proc publish::process_tag { relation_type params } {

  set tag   [template::get_attribute content $params tag]
  set index [template::get_attribute content $params index 1]
  set embed [ns_set find $params embed]
  if { $embed != -1 } { set embed t } else { set embed f }
  set parent_item_id [ns_set iget $params parent_item_id]
  
  # Concatenate all other keys into the extra arguments list
  set extra_args [publish::set_to_pairs $params \
    {tag index embed parent_item_id}]

  # Render the item, append it to the page
  # set item_id [publish::get_main_item_id]

  set command "publish::render_subitem"
  append command \
    " \[template::util::nvl \"$parent_item_id\" \$::content::item_id\]"
  append command " $relation_type $tag $index $embed"
  append command " \{$extra_args\}"

  template::adp_append_code "append __adp_output \[$command\]" 
}

# @private tag_child
#
# Implements the <tt>child</tt> tag which renders a child item.
# See the Developer Guide for more information. <br>
# The child tag format is 
# <blockquote><tt>
# &lt;child tag=<i>tag</i> index=<i>n embed args</i>&gt;
# </blockquote>
#
# @param params  The ns_set id for extra HTML parameters

template_tag child { params } {
  publish::process_tag child $params
}

# @private tag_relation
#
# Implements the <tt>relation</tt> tag which renders a related item.
# See the Developer Guide for more information. <br>
# The relation tag format is 
# <blockquote><tt>
# &lt;relation tag=<i>tag</i> index=<i>n embed args</i>&gt;
# </tt></blockquote>
#
# @param params  The ns_set id for extra HTML parameters

template_tag relation { params } {
  publish::process_tag relation $params
}


# @private tag_content
#
# Implements the <tt>content</tt> tag which renders the content
# of the current item.
# See the Developer Guide for more information. <br>
# The content tag format is simply <tt>&lt;content&gt;</tt>. The
# <tt>embed</tt> and <tt>no_merge</tt> parameters are implicit to
# the tag.
#
# @param params  The ns_set id for extra HTML parameters

template_tag content { params } {

  # Get item id/revision_id
  set item_id [publish::get_main_item_id]
  set revision_id [publish::get_main_revision_id]

  # Concatenate all other keys into the extra arguments list
  set extra_args [publish::set_to_pairs $params]

  # Add code to flush the cache

  # Render the item, return the html
  set    command "publish::get_html_body \[publish::handle_item"
  append command " \$::content::item_id"
  append command " -html \{$extra_args\} -no_merge -embed"
  append command " -revision_id \[publish::get_main_revision_id\]\]"

  template::adp_append_code "append __adp_output \[$command\]" 
}


# @private html_args
#
# Concatenate a list of name-value pairs as returned by
# <tt>set_to_pairs</tt> into a list of "name=value" pairs
# 
# @param argv   The list of name-value pairs
#
# @return An HTML string in format "name=value name=value ..."
#
# @see proc publish::set_to_pairs
 
proc publish::html_args { argv } {
  set extra_html ""
  if { ![template::util::is_nil argv] } {
    foreach { name value } $argv {
      append extra_html "$name=\"$value\" "
    }
  } 

  return $extra_html
}

# @public item_include_tag
#
# Create an include tag to include an item, in the form
# <blockquote><tt>
# include src=/foo/bar/baz item_id=<i>item_id</i> 
#   param=value param=value ...
# </tt></blockquote>
#
# @param item_id  The item id
#
# @param extra_args {}
#   A list of extra parameters to be passed to the <tt>include</tt>
#   tag, in form {name value name value ...}
#
# @return The HTML for the include tag
#
# @see proc item::item_url
# @see proc publish::html_args

proc publish::item_include_tag { item_id {extra_args {}} } {

  # Concatenate all the extra html arguments into a string
  set extra_html [publish::html_args $extra_args]""
  set item_url [item::get_url $item_id]
  return "<include src=\"$item_url\" $extra_html item_id=$item_id>"
}

##########################################################
#
# Procs for handling mime types
#

# @public handle_binary_file
#
# Helper procedure for writing handlers for binary files.
# It will write the blob of the item to the filesystem,
# but only if -embed is specified. Then, it will attempt to
# merge the image with its template. <br>
# This proc accepts exactly the same options a typical handler.
#
# @param item_id   
#    The id of the item to handle
#
# @param revision_id_ref {<i>required</i>} 
#    The name of the variable in the calling frame that will
#    recieve the revision_id whose content blob was written
#    to the filesystem. 
#
# @param url_ref   
#    The name of the variable in the calling frame that will
#    recieve the relative URL of the file in the file system
#    which contains the content blob
#   
# @param error_ref 
#    The name of the variable in the calling frame that will
#    recieve an error message. If no error has ocurred, this
#    variable will be set to the empty string ""
# 
# @option embed    
#    Signifies that the content should be embedded directly in
#    the parent item. <tt>-embed</tt> is <b>required</b> for this 
#    proc, since it makes no sense to handle the binary file
#    in any other way.
#
# @option revision_id {default The live revision for the item}
#    The revision whose content is to be used
#
# @option no_merge 
#    If present, do NOT merge with the template, in order to
#    prevent infinite recursion in the &lt;content&gt tag. In 
#    this case, the proc will return the empty string ""
#  
# @return The HTML resulting from merging the item with its 
#    template, or "" if no template exists or the <tt>-no_merge</tt>
#    flag was specified
#
# @see proc publish::handle::image 

proc publish::handle_binary_file { 
  item_id revision_id_ref url_ref error_ref args 
} {

  template::util::get_opts $args

  upvar $error_ref error_msg 
  upvar $url_ref file_url
  upvar $revision_id_ref revision_id
  set error_msg ""

  if { [template::util::is_nil opts(revision_id)] } {
    set revision_id [item::get_live_revision $item_id]
  } else {
    set revision_id $opts(revision_id)
  }
  
  # If the embed tag is true, return the html. Otherwise,
  # just write the image to the filesystem
  if { [info exists opts(embed)] } {

    set file_url [publish::write_content $revision_id \
       -item_id $item_id]

    # If write_content aborted, give up
    if { [template::util::is_nil file_url] } {
      set error_msg "No URL found for revision $revision_id, item $item_id"
      return ""
    }

    # Try to use the registered template for the image
    if { ![info exists opts(no_merge)] } {
      set code "publish::merge_with_template $item_id $args"
      set html [eval $code]
      # Return the result of merging - could be ""
      return $html
    }

    return "" 
 
  } else {
    set error_msg "No embed specified for handle_binary_file, aborting"
    return ""
  }

}


# The basic image handler. Writes the image blob to the filesystem,
# then either merges with the template or provides a default <img>
# tag. Uses the title for alt text if no alt text is specified 
# externally.

proc publish::handle::image { item_id args } {

  template::util::get_opts $args

  set html [eval publish::handle_binary_file \
     $item_id revision_id url error_msg $args]

  # If an error happened, abort
  if { ![template::util::is_nil error_msg] } {
    ns_log notice "WARNING: $error_msg"
    return ""
  }

  # Return the HTML if we have any
  if { ![template::util::is_nil html] } {
    return $html
  }

  # If the merging failed, output a straight <img> tag
  template::query image_info onerow "
    select 
      im.width, im.height, r.title as image_alt
    from 
      images im, cr_revisions r
    where 
      im.image_id = :revision_id
    and
      r.revision_id = :revision_id
  " -cache "image_info $revision_id"
  
  template::util::array_to_vars image_info

  # Concatenate all the extra html arguments into a string
  if { [info exists opts(html)] } {
    set extra_html [publish::html_args $opts(html)]
    set have_alt [expr [lsearch [string tolower $opts(html)] "alt"] >= 0]
  } else {
    set extra_html ""
    set have_alt 0
  }

  set html "<img src=$url"

  if { ![template::util::is_nil width] } {
    append html " width=\"$width\""
  }

  if { ![template::util::is_nil height] } {
    append html " height=\"$height\""
  }

  append html " $extra_html"
  
  # Append the alt text if needed
  if { !$have_alt } {
    append html " alt=\"$image_alt\""
  }
  
  append html ">"

  return $html

}

# Return the text body of the item

proc publish::handle::text { item_id args } {

  template::util::get_opts $args

  if { [template::util::is_nil opts(revision_id)] } {
    set revision_id [item::get_live_revision $item_id]
  } else {
    set revision_id $opts(revision_id)
  } 

  if { [info exists opts(embed)] } {
    # Render the child item and embed it in the code
    if { ![info exists opts(no_merge)] } {
      set code "publish::merge_with_template $item_id $args"
      set html [eval $code]
    } else {
      set html [content::get_content_value $revision_id]
    } 
  } else {

    # Just create an include tag

    # Concatenate all the extra html arguments into a string
    if { [info exists opts(html)] } {
      set extra_args $opts(html)
    } else {
      set extra_args ""
    }
  
    set html [publish::item_include_tag $item_id $extra_args]
  } 

  return $html
}


###########################################################
#
# Scheduled proc stuff

# @public set_publish_status
#
# Set the publish status of the item. If the status is live, publish the
# live revision of the item to the filesystem. Otherwise, unpublish
# the item from the filesystem.
#
# @param db          The database handle
# @param item_id     The item id
# @param new_status
#   The new publish status. Must be "production", "expired", "ready" or
#   "live"
# @param revision_id {default The live revision}
#   The revision id to be used when publishing the item to the filesystem.
# 
# @see proc publish::publish_revision
# @see proc publish::unpublish_item

proc publish::set_publish_status { db item_id new_status {revision_id ""} } {


  switch $new_status {

    production - expired {
      # Delete the published files
      publish::unpublish_item $item_id
    }

    ready {
      # Assume the live revision if none is passed in
      if { [template::util::is_nil revision_id] } {
        set revision_id [item::get_live_revision $item_id]
      }

      # Live revision doesn't exist or item is not publishable, 
      # go to production
      if { [template::util::is_nil revision_id] || \
              ![item::is_publishable $item_id] } {
        set new_status "production"
      }

      # Delete the published files
      publish::unpublish_item $item_id
    }

    live {
      # Assume the live revision if none is passed in
      if { [template::util::is_nil revision_id] } {
        set revision_id [item::get_live_revision $item_id]
      } 

      # If live revision exists, publish it
      if { ![template::util::is_nil revision_id] && \
              [item::is_publishable $item_id] } {
        publish_revision $revision_id
      } else {
        # Delete the published files
        publish::unpublish_item $item_id
        set new_status "production"
      }
    }

  }

  ns_ora dml $db "update cr_items set publish_status = :new_status
                    where item_id = :item_id" 

}
     

# @private track_publish_status
#
# Scheduled proc which keeps the publish status updated
#
# @see proc publish::schedule_status_sweep
 
proc publish::track_publish_status {} {
  
  ns_log notice "PUBLISH: Tracking publish status"

  set db [template::begin_db_transaction]

  if { [catch {

    # Get all ready but nonlive items, make them live
    template::query items multilist "
      select 
	distinct i.item_id, i.live_revision 
      from 
	cr_items i, cr_release_periods p
      where
	i.publish_status = 'ready'
      and
	i.live_revision is not null
      and 
        i.item_id = p.item_id
      and
        (sysdate between p.start_when and p.end_when)
      " -db $db 

    # Have to do it this way, or else "no active select", since
    # the other queries will clobber the current query
    foreach pair $items {
      set item_id [lindex $pair 0]
      set live_revision [lindex $pair 1]
      publish::set_publish_status $db $item_id live $live_revision
    }
    

    # Get all live but expired items, make them nonlive
    template::query items onelist "
      select 
	distinct i.item_id
      from 
	cr_items i, cr_release_periods p
      where
	i.publish_status = 'live'
      and
	i.live_revision is not null
      and 
        i.item_id = p.item_id     
      and 
	not exists (select 1 from cr_release_periods p2
		 where p2.item_id = i.item_id
		 and (sysdate between p2.start_when and p2.end_when)
	)
      " -db $db 
   
    foreach item_id $items {
      publish::set_publish_status $db $item_id expired 
    }
    

  } errmsg] } {
    ns_log notice "Error in publish::track_publish_status: $errmsg"
  }

  template::end_db_transaction
  template::release_db_handle
  
}

# @public schedule_status_sweep
#
# Schedule a proc to keep track of the publish status. Resets
# the publish status to "expired" if the expiration date has passed.
# Publishes the item and sets the publish status to "live" if 
# the current status is "ready" and the scheduled publication time
# has passed.
#
# @param interval {default 3600}
#   The interval, in seconds, between the sweeps of all items in
#   the content repository. Lower values increase the precision
#   of the publishing/expiration dates but decrease performance.
#   If this parameter is not specified, the value of the 
#   StatusSweepInterval parameter in the server's INI file is used 
#   (if it exists).
#   
# @see proc publish::set_publish_status
# @see proc publish::unschedule_status_sweep
# @see proc publish::track_publish_status

proc publish::schedule_status_sweep { {interval ""} } {

  if { [template::util::is_nil interval] } {
    # Kludge: relies on that CMS is a singleton package
    set package_id [apm_package_id_from_key "cms"]
    set interval [ad_parameter -package_id $package_id StatusSweepInterval 3600]
  }

  ns_log notice "CMS publish::schedule_status_sweep: Scheduling status sweep every $interval seconds"
  set proc_id [ns_schedule_proc -thread $interval publish::track_publish_status]
  cache set status_sweep_proc_id $proc_id
  
}


# @public unschedule_status_sweep
#
# Unschedule the proc which keeps track of the publish status. 
#
# @see proc publish::schedule_status_sweep

proc publish::unschedule_status_sweep {} {
  
  set proc_id [cache get status_sweep_proc_id]
  if { ![template::util::is_nil proc_id] } {
    ns_unschedule_proc $proc_id
  }
}
  

# Actually schedule the status sweep

publish::schedule_status_sweep

