request create -params {
  parent_id -datatype integer
}

query path onevalue "
  select content_item.get_path(:parent_id) from dual"

form create new_folder -elements "
  return_url -datatype url -widget hidden
  folder_id -datatype integer -widget hidden
  parent_id -datatype integer -widget hidden
  name -datatype filename -html { size 40 } -label {Folder Name}
  label -datatype text -html { size 40 } -optional
  description -datatype text -widget textarea -optional \
    -html { rows 4 cols 40 }
"

if { [form is_request new_folder] } {

  element set_value new_folder folder_id [content::get_object_id]
  element set_value new_folder parent_id $parent_id

  set return_url [ns_set iget [ns_conn headers] Referer]
  element set_properties new_folder return_url -value $return_url

} else {

  set return_url [element get_value new_folder return_url]
}

if { [string equal [ns_queryget action] "Cancel"] } {
  template::forward $return_url
}

if { [form is_valid new_folder] } {

  form get_values new_folder parent_id name folder_id label description

  set creation_ip [ns_conn peeraddr]
  set creation_user [User::getID]

  set db [template::begin_db_transaction]

  set sql "begin :folder_id := content_folder.new(
         folder_id => :folder_id,
         name => :name,
         label => :label,
         description => :description,
         parent_id => :parent_id,
         creation_ip   => :creation_ip,
         creation_user => :creation_user
  ); end;"

  ns_ora exec_plsql_bind $db $sql folder_id

  content::add_basic_revision $folder_id "" "Template" \
      -text "<html></html>"

  template::end_db_transaction

  template::forward $return_url
}