request create -params {
  id -datatype integer
  path -datatype text
  tab -datatype keyword -value revisions
}

if { ! [string equal $path {}] } {

  template::query get_id id onevalue "
    select 
      content_item.get_id(:path, content_template.get_root_folder) 
    from dual"

  if { [string equal $id {}] } {

    set msg "The requested folder <tt>$path</tt> does not exist."
    request error invalid_path $msg
  }

} else {

  if { [string equal $id {}] } {
    template::query get_root_id onevalue "
      select content_template.get_root_folder from dual"
  }

  template::query get_path path onevalue "
    select content_item.get_path(:id) from dual"
}

# query for the content type and redirect if a folder

template::query get_type type onevalue "
  select content_type from cr_items where item_id = :id"

if { [string equal $type content_folder] } {
  template::forward index?id=$id
}

multirow create tabs label name
multirow append tabs General general
multirow append tabs History revisions
multirow append tabs {Data Sources} datasources
multirow append tabs Assets assets
multirow append tabs {Content Types} types
multirow append tabs {Content Items} items

set tab_count [expr ${tabs:rowcount} * 2]
