# ancestors.tcl
# show ancestors with navigational links to view them
# shows path with possible link to 'preview' the item
#   if the item is a sitemap folder and has an index item
#   if the item is not a folder and is under the sitemap mount point

request create -params {
    item_id -datatype integer
    mount_point -datatype keyword -value sitemap
    index_page_id -datatype integer -optional
}

set root_id [cm::modules::${mount_point}::getRootFolderID]

# special case - when the item_id is null, set it to the root folder
if { [template::util::is_nil item_id] } {
    set item_id $root_id
}


# Get the cookie; prepare for setting bookmarks
#set clip [clipboard::parse_cookie]

# use the appropriate icon depending on whether the item is bookmarked or not
# sets this_item(bookmark) as the icon
#set bookmark [clipboard::get_bookmark_icon $clip $mount_point $item_id]

# get the context bar info

template::query get_context context multirow "
  select
    t.tree_level, t.parent_id, 
    content_folder.is_folder(i.item_id) is_folder,
    content_item.get_title(t.parent_id) as title
  from 
    cr_items i,
    (
      select 
        parent_id, level as tree_level
      from 
        cr_items
      where
        parent_id ^= 0
      connect by
        prior parent_id = item_id
      start with
        item_id = :item_id
    ) t
  where
    i.item_id = t.parent_id
  order by
    tree_level desc"


# pass in index_page_id to improve efficiency
if { ![template::util::is_nil index_page_id] } {

    set index_page_sql ""
    set has_index_page t

} else {
    set index_page_sql [db_map index_page_p]
}

# get the path of the item

template::query get_preview_info preview_info onerow "
  select
    $index_page_sql 
    -- does it have a template
    content_item.get_template( item_id, 'public' ) template_id,
    -- symlinks to this folder will have the path of this item
    content_item.get_virtual_path( item_id, :root_id ) virtual_path,
    content_item.get_path( 
      content_symlink.resolve( item_id ), :root_id ) physical_path,
    content_folder.is_folder( item_id ) is_folder,
    live_revision
  from
    cr_items
  where 
    item_id = :item_id" 

template::util::array_to_vars preview_info


template::util::array_to_vars preview_info
# physical_path, virtual_path, is_folder, has_index_page

if { [string equal $physical_path "../"] } {
    set display_path "/"
} else {
    set display_path "/$physical_path"
}

# preview_p - flag indicating whether the path is previewable or not
#   t => if the item is a sitemap folder and has an index item
#   t => if the item is not a folder and is under the sitemap mount point
set preview_p f
set preview_path $virtual_path

# Determine the root of the preview link. If CMS is running as a package,
# the index.vuh file should be under this root.
if { [catch {
  set root_path [ad_conn package_url]
} errmsg] } {
  set root_path ""
}

#set preview_path [ns_normalizepath "$root_path/$preview_path"]
set preview_path [ns_normalizepath "/$preview_path"]


if { [string equal $mount_point sitemap] } {
    if { [string equal $is_folder t] && [string equal $has_index_page t] } {
	set preview_p t
    } elseif { ![string equal $is_folder t] && \
	    ![template::util::is_nil live_revision] } {
	    set preview_p t
    }
}
# an item cannot be previewed if it has no associated template
if { [string equal $has_index_page t] } {
    template::query get_template_id template_id onevalue "
      select 
        content_item.get_template( 
          nvl( content_folder.get_index_page( :item_id ), 0), 'public' )
      from
        dual
    " 
}

if { [template::util::is_nil template_id] } { 
    set preview_p f
}

