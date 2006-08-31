ad_page_contract {
    Unregister a content type from a folder

    @author Michael Steigman
    @creation-date October 2004
} {
    { folder_id:integer }
    { content_type:multiple }
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $folder_id -privilege write

foreach type $content_type {
    content::folder::unregister_content_type -folder_id $folder_id \
	-content_type $type -include_subtypes f
}

ad_returnredirect [export_vars -base folder-attributes folder_id]
