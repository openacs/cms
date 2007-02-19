ad_page_contract {
    Change name of a content item

    @author Michael Steigman
    @creation-date April 2006
} {
    { item_id:integer }
    { mount_point:optional "sitemap" }
    { return_url }
    { tab:optional }
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $item_id -privilege read

set content_type [content::item::get_content_type -item_id $item_id]
if { $content_type eq "content_template" } {
    cms::template::get -template_id $item_id -array_name content_item
} elseif { $content_type eq "image" } {
    cms::image::get -image_id $item_id
} else {
    content::item::get -item_id $item_id -revision latest
}
set name $content_item(name)
    
set page_title "Rename $name"

form create rename_item -cancel_url $return_url

element create rename_item mount_point \
    -datatype text \
    -widget hidden \
    -value $mount_point \
    -optional

element create rename_item content_type \
    -datatype text \
    -widget hidden \
    -value $content_type \
    -optional

element create rename_item return_url \
    -datatype text \
    -widget hidden \
    -value $return_url \
    -optional

element create rename_item item_id \
    -datatype integer \
    -widget hidden \
    -param

element create rename_item name \
    -label "Rename $name to" \
    -datatype text \
    -widget text \
    -html { size 20 } \
    -validate { { expr ![string match $value "/"] } \
		    { Item name cannot contain slashes }} \
    -value $name \
    -help_text "Short name using no special characters and without file extension"

# Rename
if { [form is_valid rename_item] } {

  form get_values rename_item \
	  mount_point item_id name content_type

  # handle file system stuff for templates
  if { $content_type eq "content_template" } {
      #cms::template::rename -template_id $item_id -name $name
  }  
  content::item::rename -item_id $item_id -name $name

  set base_url [ad_decode $content_type content_template "../templates/properties" "../items/index"]
  ad_returnredirect [export_vars -base $base_url {item_id tab}]
  ad_script_abort
}
