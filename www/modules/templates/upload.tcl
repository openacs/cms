ad_page_contract {

    @author Michael Steigman
    @creation-date May 2005
} {
    { template_id:integer }
    { mount_point "templates"}
    { tab:optional "revision"}
    { return_url }
}

if { ! [request is_valid] } { return }

set template_root [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]
set path [content::template::get_path -template_id $template_id -root_folder_id $template_root]

form create edit_template -html { enctype multipart/form-data } -cancel_url $return_url

element create edit_template return_url -datatype url -widget hidden

element create edit_template template_id -datatype integer \
    -value $template_id -widget hidden

element create edit_template revision_id -datatype integer -widget hidden

element create edit_template content -widget file -label Local File \
    -datatype text -html { size 50 }

if { [form is_request edit_template] } {
  
  element set_properties edit_template revision_id \
      -value [cms::form::new_object_id]

  element set_properties edit_template return_url -value $return_url

} 

if { [string equal [ns_queryget action] "Cancel"] } {
  template::forward $return_url
}

if { [form is_valid edit_template] } {

  form get_values edit_template template_id revision_id

  set tmpfile [cms::form::prepare_content_file edit_template]

  cms::form::add_basic_revision $template_id $revision_id "Template" \
      -tmpfile $tmpfile

  template::forward $return_url
}
    

