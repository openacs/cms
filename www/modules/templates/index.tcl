# List the contents of a folder under in the template repository

# Either a path or a folder ID may be passed to the page.

request create -params {
  id -datatype integer
  path -datatype text
}

set package_url [ad_conn package_url]
set clipboardfloats_p [clipboard::floats_p]

# Tree hack
if { $id == [cm::modules::templates::getRootFolderID] } {
  set refresh_id ""
} else {
  set refresh_id $id
}

if { ! [string equal $path {}] } {

  query id onevalue "
    select 
      content_item.get_id(:path, content_template.get_root_folder) 
    from dual"

  if { [string equal $id {}] } {

    set msg "The requested folder <tt>$path</tt> does not exist."
    request error invalid_path $msg
  }
} else {

  if { [string equal $id {}] } {
    query id onevalue "
      select content_template.get_root_folder from dual"
  }

  query path onevalue "
    select content_item.get_path(:id) from dual"
}

# query for the content type and redirect if a folder

query type onevalue "
  select content_type from cr_items where item_id = :id"

if { [string equal $type content_template] } {
  template::forward properties?id=$id
}

# Query for the parent

if { ! [string equal $path /] } {
query parent onerow "
  select
    f.folder_id, f.label, i.name, 
    to_char(o.last_modified, 'MM/DD/YY HH:MI AM') modified
  from
    cr_folders f, cr_items i, acs_objects o
  where
    i.item_id = (select parent_id from cr_items where item_id = :id)
  and
    i.item_id = f.folder_id
  and
    i.item_id = o.object_id"
}

# Query folders first

query folders multirow "
  select
    f.folder_id, f.label, i.name, 
    to_char(o.last_modified, 'MM/DD/YY HH:MI AM') modified
  from
    cr_folders f, cr_items i, acs_objects o
  where
    i.parent_id = :id
  and
    i.item_id = f.folder_id
  and
    i.item_id = o.object_id
  order by
    upper(f.label), upper(i.name)"

# items in the folder

query items multirow "
  select
    t.template_id, i.name, 
    to_char(o.last_modified, 'MM/DD/YY HH:MI AM') modified,
    nvl(round(dbms_lob.getlength(r.content) / 1000), 0) || ' KB' as file_size
  from
    cr_templates t, cr_items i, acs_objects o, cr_revisions r
  where
    i.parent_id = :id
  and
    i.item_id = t.template_id
  and
    i.item_id = o.object_id
  and
    i.latest_revision = r.revision_id (+)
  order by
    upper(i.name)"

# set a flag indicating whether the folder is empty

set is_empty [expr ! ( ${items:rowcount} || ${folders:rowcount} )]