##########################
#
# Procedures to manipulate the clipboard
#
################

namespace eval clipboard {
  
  # Get the clipboard from a cookie and return it
  proc parse_cookie {} { 
    set clipboard_cookie [template::util::get_cookie content_marks]   
    ns_log notice $clipboard_cookie
    set clip [ns_set create]
    set mount_branches [split $clipboard_cookie "|"]
    set mount_points [list]
    set total_items 0
      
    foreach branch $mount_branches {
      if { [regexp {([a-zA-Z0-9]+):(.*)} $branch match mount_point items] } {
        ns_log notice "CLIP: $branch"
        set items_list [split $items ","]  
        set items_size [llength $items_list]
        incr total_items $items_size
        ns_set update $clip $mount_point $items_list
        ns_set update $clip ${mount_point}_size $items_size
        lappend mount_points $mount_point
      }
    }

    ns_set put $clip __total_items__ $total_items
    ns_set put $clip __mount_points__ $mount_points
      
    return $clip
  }

  # Retreive all marked items as a list
  proc get_items { clip mount_point } {
    return [ns_set get $clip $mount_point]
  }

  # Get the number of total items on the clipboard
  proc get_total_items { clip } {
    return [ns_set get $clip __total_items__]
  }

  # Execute a piece of code for each item under the
  # specified mount point, creating an item_id
  # variable for each item id
  proc map_code { clip mount_point code } {
    set item_id_list [ns_set get $clip $mount_point]
    foreach id $item_id_list {
      uplevel "set item_id $id; $code"
    }
  }

  # Determine if an item is marked
  proc is_marked { clip mount_point item_id } {
    if { [lsearch -exact \
            [get_items $clip $mount_point] \
            $item_id] > -1} { 
      return 1
    } else {
      return 0
    }
  }

  # Use this function as part of the multirow query to
  # set up the bookmark icon
  proc get_bookmark_icon { clip mount_point item_id {row_ref row} } {
    upvar $row_ref row

    if { [clipboard::is_marked $clip $mount_point $item_id] } {
      set row(bookmark) Bookmarked
    } else {
      set row(bookmark) Bookmarks
    }

    return $row(bookmark)
  }

  # Add an item to the clipboard: BROKEN
  proc add_item { clip mount_point item_id } {
    set old_items [ns_set get $clip $mount_point]
    if { [lsearch $old_items $item_id] == -1 } {

      # Append the item
      lappend old_items $item_id
      ns_set update $clip $mount_point $old_items
      ns_set update $clip ${mount_point}_size \
        [expr [ns_set get $clip ${mount_point}_size] + 1]
      ns_set update $clip __total_items__ \
        [expr [ns_set get $clip __total_items__] + 1]
    
      # Append the mount point
      set old_mount_points [ns_set get $clip __mount_points__]
      if { [lsearch -exact $old_mount_points $mount_point] == -1 } {
        lappend old_mount_points $mount_point
        ns_set update $clip __mount_points__ $old_mount_points
      }
    }
  }

  # Remove an item from the clipboard: BROKEN
  proc remove_item { clip mount_point item_id } {
    set old_items [ns_set get $clip $mount_point]
    set index [lsearch $old_items $item_id]
    if { $index !=  -1 } {

      # Remove the item
      set old_items [lreplace $old_items $index $index ""]
      ns_set update $clip $mount_point $old_items
      ns_set update $clip ${mount_point}_size \
        [expr [ns_set get $clip ${mount_point}_size] - 1]
      ns_set update $clip __total_items__ \
        [expr [ns_set get $clip __total_items__] - 1]
    }
  }

  # Actually set the new cookie: BROKEN
  proc set_cookie { clip } {
    set the_cookie ""
    set mount_point_names [ns_set get $clip __mount_points__] 
    set pipe ""
    foreach mount_point $mount_point_names {
      append the_cookie "$pipe${mount_point}:[join [ns_set get $clip $mount_point] ,]"
      set pipe "|"
    }

    template::util::set_cookie session content_marks $the_cookie
  }

  # Clear the clipboard: BROKEN
  proc clear_cookie {} {
    template::util::clear_cookie content_marks
  }

  # Release the resources associated with the clipboard
  proc free { clip } {
    ns_set free $clip
  }

  # determines whether clipboard should float or not
  # currently incomplete, should be checking user prefs
  proc floats_p {} {
	return [ad_parameter ClipboardFloatsP]

  }

  # See clipboard-ui-procs.tcl
  namespace eval ui {}

}
 
  
   
