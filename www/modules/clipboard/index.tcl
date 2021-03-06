# Display a list of items on the clipboard

set heads [ad_conn headers]
set package_url [ad_conn package_url]
set clipboardfloats_p [clipboard::floats_p]

for { set i 0 } { $i < [ns_set size $heads] } { incr i } {
  ns_log notice "[ns_set key $heads $i] = [ns_set value $heads $i]"
}

request create
request set_param id -datatype keyword -optional
request set_param parent_id -datatype keyword -optional
request set_param state -datatype text -param -optional -value [list]
request set_param mount_point -datatype keyword -optional -value clipboard
request set_param clip_tab -datatype keyword -optional -value main

# using the tabs to set the page id;
# then making sure that the tabs display the correct page
if {![template::util::is_nil clip_tab]} {
    if {$clip_tab == "main" } {
	set id ""
    } else {
	set id $clip_tab
    }
}

if {$id == "" } {
    set curr_tab main
} else {
    set curr_tab $id
}

# The cookie for the clipboard looks like this:
# mnt:id,id,id|mnt:id,id,id|mnt:id,id,id.

set clip [clipboard::parse_cookie]

set total_items [clipboard::get_total_items $clip]
set user_id [auth::require_login]

if { ![util::is_nil id] } {
  
  set item_id_list [clipboard::get_items $clip $id]
  ns_log Notice "item_id_list = [join $item_id_list ","]"

  # First, attempt to ask the module for the list of item paths in sorted order
  # Could fail because of some SQL error or because the procedure does not exist

  if { [catch { 
      cm::modules::${id}::getSortedPaths items $item_id_list \
          [cm::modules::${id}::getRootFolderID [ad_conn package_id]]

      template::multirow extend items url
      template::multirow foreach items { 
          switch $item_type {
              content_template { 
                  set url "../templates/properties?id=$item_id"
              }
              party {
                  set url "../$id/index?id="
              }
              user {
                  set url "../$id/one-user?id=$item_id"
              }
              default {
                  set url "../$id/index?id=$item_id"
              }
          }
          # this is for all items in the sitemap that need to be listed under the
          # item folder
          if {$id == "sitemap" && $item_type != "content_folder"} {
              set url "../items/index?item_id=$item_id"
          }
          append url "&mount_point=$id"
      }
  } errmsg ] } {
      # Process the list manually. Path information will not be shown, but at least
      # the names will be

      ns_log Warning "CLIPBOARD ERROR: $errmsg"
      template::multirow create items item_id item_path item_type url

      foreach item_id $item_id_list {
          if { [string equal $item_id "content_revision"] && [string equal $id "types"] } {
              set link_id ""
              set item_path "Basic Item"
          } else {
              set link_id $item_id
              set item_path [folderAccess name [getFolder $user_id $id $link_id state]]
          } 
          set item_type ""
          set url "../$id/index?id=$link_id"
          
          template::multirow append items $item_id $item_path $item_type $url
      }
  }
}

set url [ad_conn url]
append url "?mount_point=clipboard&id=$id&parent_id=$parent_id&refresh_tree=f"
