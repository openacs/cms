ad_page_contract {

    Add a revision of the item

} {
    { item_id:integer }
    { revision_id:integer }
    { mount_point:optional "sitemap" }
    { content_method "no_content" }
    { return_url:optional "" }
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $item_id -privilege write

# get content_type and name of item
content::item::get -item_id $item_id -revision latest

# validate item_id
# if { [template::util::is_nil content_type] } {
#   template::request::error add_revision "Error - invalid item_id - $item_id"
# }

set page_title "Add a Revision to $content_item(name)"

# check for custom revision-add-1 form
if { [file exists [ns_url2file \
		       "custom/$content_item(content_type)/revision-add-1.tcl"]] } {
    template::forward "custom/$content_type/revision-add-1?item_id=$item_id&content_method=$content_method"
}

form create add_revision -html { enctype "multipart/form-data" } -cancel_url $return_url

element create add_revision return_url \
    -datatype text \
    -widget hidden \
    -value $return_url \
    -optional

element create add_revision creation_user \
    -datatype text \
    -widget hidden \
    -value [ad_conn user_id] \
    -optional

element create add_revision creation_ip \
    -datatype text \
    -widget hidden \
    -value [ad_conn peeraddr] \
    -optional

# autogenerate the revision form
cms::form::add_revision_form \
    -form_name add_revision \
    -content_method $content_method \
    -content_type $content_item(content_type) \
    -item_id $item_id \
    -revision_id $revision_id
    
if { [form is_valid add_revision] } {
    form get_values add_revision item_id
    # autoprocess the revision form
    cms::form::add_revision add_revision

    ad_returnredirect [export_vars -base index item_id]
}
