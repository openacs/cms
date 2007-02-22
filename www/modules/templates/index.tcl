ad_page_contract {
    List the contents of a folder under in the template repository
    Either a path or a folder ID may be passed to the page.

    @author Michael Steigman
    @creation-date October 2004
} {
    { folder_id:integer ""}
    { mount_point "templates" }
    { parent_id:integer ""}
    { orderby "title,asc" }
    { page:optional ""}
    { path:optional "" }
}

set package_url [ad_conn package_url]

# the ability to pass in a path is not currently utilized by any CMS pages
if { $path ne "" } {
    set folder_id [content::item::get_id -item_path $path]
    if { $folder_id eq "" } {
	ad_return_complaint 1 "The requested folder \"$path\" does not exist."
    }
} else {
  if { $folder_id eq "" } {
      set folder_id [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]  
  }
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $folder_id -privilege read

cms::folder::get -folder_id $folder_id
set return_url [ad_return_url]

set actions "\"Folder Attributes\" [export_vars -base ../sitemap/folder-attributes?mount_point=templates {folder_id return_url}] \"Folder Attributes\"
\"Delete Folder\" [export_vars -base ../sitemap/folder-delete {mount_point folder_id parent_id return_url}] \"Delete this folder\"
\"Edit Folder Info\" [export_vars -base ../sitemap/folder-ae {mount_point folder_id return_url}] \"Rename this folder\"
\"New Template\" [export_vars -base template-ae {mount_point folder_id return_url}] \"Create a new template within this folder\"
\"New Folder\" [export_vars -base ../sitemap/folder-ae?parent_id=$folder_id {mount_point return_url}] \"Create a new folder within this folder\"
\"Move Items\" [export_vars -base ../sitemap/manage-items?list_action=move {mount_point folder_id return_url}] \"Move marked items to this folder\"
\"Copy Items\" [export_vars -base ../sitemap/manage-items?list_action=copy {mount_point folder_id return_url}] \"Copy marked items to this folder\"
\"Delete Items\" [export_vars -base ../sitemap/manage-items?list_action=delete {mount_point folder_id return_url}] \"Delete marked items to this folder\"
"
