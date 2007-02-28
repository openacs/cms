ad_page_contract {
    Display content types that are registered to this folder

    @author Michael Steigman
    @creation-date October 2004
} {
    { folder_id:integer,optional "" }
    { folder_resolved_id:integer,optional }
    { mount_point "sitemap" }
    { folder_props_tab "registered" }
    { return_url:optional }
}

# default folder_id is the root folder
if { $folder_id eq "" } {
    set folder_id [cm::modules::${mount_point}::getRootFolderID [ad_conn subsite_id]]
}

cms::folder::get -folder_id $folder_id

if { [template::util::is_nil folder_resolved_id] } {
    set folder_resolved_id $folder_id
}

permission::require_permission -party_id [auth::require_login] \
    -object_id $folder_id -privilege read

# Get the registered types for the folder 
# (besides symlinks/templates/subfolders)
cms::folder::get_registered_types $folder_id multirow content_types

#set type-unreg-url 
template::list::create \
    -name content_types \
    -multirow content_types \
    -key content_type \
    -bulk_actions [list	"Unregister checked types from this folder" \
		       "[export_vars -base type-unregister?mount_point=sitemap {folder_id}]" \
		       "Unregister checked types from this folder"] \
    -bulk_action_export_vars folder_id \
    -actions [list "Register content types on clipboard to this folder" \
		  [export_vars -base type-register?mount_point=sitemap {folder_id}] "Register clipped content types to this folder"] \
    -elements {
	pretty_name {
	    label "Content Type"
	}
	
    }

# Set other misc values
set page_title "Folder Attributes - $folder_info(label)"
set return_url [ad_return_url]

# Determine registered types
set type_list [cms::folder::get_registered_types $folder_id list]
set subfolders_p [ad_decode [lsearch $type_list content_folder] -1 f t]
set symlinks_p [ad_decode [lsearch $type_list content_symlink] -1 f t]

# Create the form for registering special types to the folder
ad_form -name special_types \
    -form {
	{allow_subfolders:boolean(radio)
	    {label "Allow Subfolders?"}
	    {options {{Yes t} {No f}}}
	    {value $subfolders_p}
	}
	{allow_symlinks:boolean(radio)
	    {label "Allow Symlinks?"}
	    {options {{Yes t} {No f}}}
	    {value $symlinks_p}
	}
	{folder_resolved_id:integer(hidden),optional}
	{mount_point:text(hidden)}
	{folder_id:integer(hidden)}
	{folder_props_tab:text(hidden)}
    } \
    -on_request {} \
    -on_submit {

	permission::require_permission -party_id [auth::require_login] \
	    -object_id $folder_id -privilege write

        if { $allow_subfolders eq "t" } {
	    content::folder::register_content_type -folder_id $folder_id \
		-content_type content_folder
        } else {
	    content::folder::unregister_content_type -folder_id $folder_id \
		-content_type content_folder
        }
	
        if { $allow_symlinks eq "t" } {
	    content::folder::register_content_type -folder_id $folder_id \
		-content_type content_symlink
        } else {
	    content::folder::unregister_content_type -folder_id $folder_id \
		-content_type content_symlink
        }
	
    } \
    -after_submit {
	ad_returnredirect [export_vars -base folder-attributes {folder_id mount_point folder_props_tab}]
	ad_script_abort
    }
