# display content-types that are registered to this folder

request create
request set_param folder_id   -datatype integer -optional
request set_param mount_point -datatype keyword -value sitemap

# default folder_id is the root folder
if { [template::util::is_nil folder_id] } {
    set folder_id [cm::modules::${mount_point}::getRootFolderID]
}

set db [template::get_db_handle]

# permissions check - user must have cm_examine on this folder
content::check_access $folder_id cm_examine -user_id [User::getID] -db $db


# Get the registered types for the folder 
# (besides symlinks/templates/subfolders)
cms_folder::get_registered_types $folder_id multirow content_types

# Get other misc values
query folder_name onevalue "
  select label from cr_folders where folder_id = :folder_id
" 

set page_title "Folder Attributes - $folder_name"
set register_marked_content_types \
	"<a href=\"type-register?folder_id=$folder_id\">
         <img src=\"../../resources/Add24.gif\" 
           width=24 height=24 border=0 
           alt=\"Register marked content types.\">
           Register marked content types to this folder.</a>"

# Set up passthrough for permissions
set return_url [ns_conn url]
set passthrough [content::assemble_passthrough \
                  return_url mount_point folder_id]


# Determine registered types
query folder_options onerow "
  select
    content_folder.is_registered(:folder_id,'content_folder') allow_subfolders,
    content_folder.is_registered(:folder_id,'content_symlink') allow_symlinks,
    content_folder.is_registered(:folder_id,'content_template') allow_templates
  from dual
" 

template::release_db_handle


# Create the form for registering special types to the folder
form create register_types

element create register_types folder_resolved_id \
	-datatype integer \
	-widget hidden \
	-optional

# PATCH to set a negative number (with a dash in front of it) as the value
if { [util::is_nil "register_types:folder_resolved_id(value)"] } {
  set "register_types:folder_resolved_id(value)" $folder_id
}

element create register_types folder_id \
	-datatype integer \
	-widget hidden \
	-param -optional

element create register_types mount_point \
	-datatype keyword \
	-widget hidden \
	-param -optional

element create register_types allow_subfolders \
	-datatype keyword \
	-widget radio \
	-label "Allow Subfolders?" \
	-options { {Yes t} {No f} } \
	-values [list $folder_options(allow_subfolders)]

element create register_types allow_symlinks \
	-datatype keyword \
	-widget radio \
	-label "Allow Symlinks?" \
	-options { {Yes t} {No f} } \
	-values [list $folder_options(allow_symlinks)]


# Process the form

if { [form is_valid register_types] } {

    form get_values register_types \
	    allow_subfolders allow_symlinks folder_resolved_id mount_point

    set db [template::begin_db_transaction]

    # permissions check - must have cm_write on folder to modify its options
    content::check_access $folder_resolved_id cm_write \
	    -user_id [User::getID] -db $db


    if { [string equal $allow_subfolders "t"] } {
	set subfolder_sql "content_folder.register_content_type(:folder_resolved_id,'content_folder');"
    } else {
	set subfolder_sql "content_folder.unregister_content_type(:folder_resolved_id,'content_folder');"
    }

    if { [string equal $allow_symlinks "t"] } {
	set symlink_sql "content_folder.register_content_type(:folder_resolved_id,'content_symlink');"
    } else {
	set symlink_sql "content_folder.unregister_content_type(:folder_resolved_id,'content_symlink');"
    }

    set sql "begin
             $subfolder_sql
             $symlink_sql
             end;"

    ns_ora dml $db $sql
    template::end_db_transaction 
    template::release_db_handle

    forward "attributes?folder_id=$folder_id&mount_point=$mount_point"
}
