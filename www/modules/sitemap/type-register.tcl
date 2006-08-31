ad_page_contract {
    Register content types from clipboard to a folder

    @author Michael Steigman
    @creation-date October 2004
} {
    { folder_id:integer }
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $folder_id -privilege write

set clip [cms::clipboard::parse_cookie]
set marked_types [cms::clipboard::get_items $clip "types"]
    
db_transaction {
    foreach type $marked_types {
	content::folder::register_content_type -folder_id $folder_id \
	    -content_type $type -include_subtypes f
    }
}

cms::clipboard::free $clip

ad_returnredirect [export_vars -base folder-attributes folder_id]
