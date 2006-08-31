ad_page_contract {
    see if this person is authorized to read the file in question

} {
    { item_id:integer }
    { revision_id:integer }
}

# check permissions on file
if { ![content::revision::is_live -revision_id $revision_id] } {
    permission::require_permission -party_id [auth::require_login] \
	-object_id $item_id -privilege read
}

cr_write_content -revision_id $revision_id
