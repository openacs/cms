request create -params {
  folder_id -datatype integer
}

ns_log Notice "folder_id is $folder_id"

template::query get_path path onevalue "
  select content_item.get_path(:folder_id) from dual"

form create new_template -elements "
  return_url -datatype url -widget hidden
  template_id -datatype integer -widget hidden
  folder_id -datatype integer -widget hidden
  name -datatype filename -html { size 40 }
"

template::query get_mime_types mime_types multilist "
  select label, m.mime_type from cr_mime_types m, cr_content_mime_type_map t
  where t.content_type = 'content_template' and t.mime_type = m.mime_type"

element create new_template mime_type -widget select -label "Template Type" \
    -datatype text -options $mime_types

if { [form is_request new_template] } {

  element set_value new_template template_id [content::get_object_id]
  element set_value new_template folder_id $folder_id

  set return_url [ns_set iget [ns_conn headers] Referer]
  element set_properties new_template return_url -value $return_url

} else {

  set return_url [element get_value new_template return_url]
}

if { [string equal [ns_queryget action] "Cancel"] } {
  template::forward $return_url
}

if { [form is_valid new_template] } {

  form get_values new_template template_id name folder_id mime_type

  set creation_ip [ns_conn peeraddr]
  set creation_user [User::getID]

  db_transaction {


      set template_id [db_exec_plsql new_template "begin :1 := content_template.new(
         template_id => :template_id,
         name => :name,
         parent_id => :folder_id,
         creation_ip   => :creation_ip,
         creation_user => :creation_user
  ); end;"]

      content::add_basic_revision $template_id "" "Template" \
          -text "<html></html>" -mime_type $mime_type
  }

  template::forward $return_url
}
