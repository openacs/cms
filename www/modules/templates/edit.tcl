request create -params {
  template_id -datatype integer
  edit_revision -datatype integer -optional
}

if { ! [request is_valid] } { return }

template::query get_path path onevalue "
  select content_item.get_path(:template_id) from dual"

form create edit_template -html { enctype multipart/form-data }

element create edit_template return_url -datatype url -widget hidden

element create edit_template template_id -datatype integer \
    -value $template_id -widget hidden

element create edit_template revision_id -datatype integer -widget hidden

element create edit_template content -widget textarea -label {} \
    -datatype text -html { cols 80 rows 30 } template

template::query get_mime_types mime_types multilist "
  select label, m.mime_type from cr_mime_types m, cr_content_mime_type_map t
  where t.content_type = 'content_template' and t.mime_type = m.mime_type"

element create edit_template mime_type -widget select -label "Template Type" \
    -datatype text -options $mime_types

element create edit_template is_update -widget radio -optional \
    -label "Create New Revision" -datatype keyword \
    -options { {"Yes" "t" } { "No" "f" } } -value "f"






if { [form is_request edit_template] } {
  
  element set_value edit_template revision_id [content::get_object_id]

  if { [string equal $edit_revision {}] } {

    set edit_revision [content::get_latest_revision $template_id]
  }

  # if a revision exists, display it
  if { ![template::util::is_nil edit_revision] } {

      # can't update an existing revision if there is none
      element set_properties edit_template is_update -values t

      element set_value edit_template content \
	      [content::get_content_value $edit_revision]

      template::query get_mime_type mime_type onevalue "
        select mime_type from cr_revisions where revision_id = :edit_revision"

      element set_value edit_template mime_type $mime_type      
  }

  set return_url [ns_set iget [ns_conn headers] Referer]
  element set_value edit_template return_url $return_url

} else {

  set return_url [element get_value edit_template return_url]
}


if { [string equal [ns_queryget action] "Cancel"] } {
  template::forward $return_url
}










if { [form is_valid edit_template] } {

  form get_values edit_template template_id revision_id is_update mime_type

  set tmpfile [content::prepare_content_file edit_template]

  template::query get_revision_count revision_count onevalue "
    select count(revision_id) from cr_revisions where item_id = :template_id"

  if { $revision_count == 0 } {
      set is_update t
  }

  if { [string equal $is_update "t"] } {

    content::add_basic_revision $template_id $revision_id "Template" \
        -tmpfile $tmpfile -mime_type $mime_type

  } else {

    set revision_id [content::get_latest_revision $template_id]
    content::update_content_from_file $revision_id $tmpfile
  }

  template::forward $return_url
}
    

