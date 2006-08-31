ad_library {

    Procs for content_template, and some helper procs

}

namespace eval cms::template {}

ad_proc -public cms::template::get {
    -template_id:required
    {-revision_id "" }
    {-array_name "template_info" }
} {
    get a template revision

    @param template_id             item id of the template you want
    @return array 
    
} {

    if { $revision_id eq "" } {
	set revision_id [content::item::get_latest_revision -item_id $template_id]
    }
    upvar $array_name local_array
    return [db_0or1row select_template {} -column_array local_array]

}

ad_proc -public cms::template::add_revision {
    -template_id:required
    { -title "" }
    { -description "" }
    { -content "" }
    { -mime_type "" }
    { -creation_user "" }
    { -creation_ip "" }
} {
    add a template revision


    @param template_id             item id of the template you want to add a new revision to
    @param title                   title of the template
    @param description             description of the template
    @param content                 content of the template
    @param mime_type               mime type for template
    @param creation_user           user_id creating this item
    @param creation_ip             ip address which this item is created

    @return revision_id
    
} {
    return [db_exec_plsql add_revision {}]
}

ad_proc -public cms::template::mime_type_options {} {
    return template mime_types
} {
    return [db_list_of_lists get_mime_types {}]
}

ad_proc -public cms::template::move {
    -template_id:required
    -target_folder_id:required
} {
    Handle the file system part of deleting a template. You must also call content::item::move.

    @see content::item::move    
} {

    set template_root [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]
    set base_path "[acs_root_dir]/templates"
    set existing_path "${base_path}/[content::template::get_path -template_id $template_id -root_folder_id $template_root]"
    # need actual template name; could split the path above but this is just as easy if a bit slower
    cms::template::get -template_id $template_id
    set new_path "${base_path}/[content::item::get_path -item_id $target_folder_id -root_folder_id $template_root]"
    file mkdir $new_path
    if { [catch { file rename -force ${existing_path}.adp ${new_path}/$template_info(name).adp } err] } {
	ns_log debug "cms::template::move: encountered error moving template adp: $err"
    }
    if { [catch { file rename -force ${existing_path}.tcl ${new_path}/$template_info(name).tcl } err] } {
	ns_log debug "cms::template::move: encountered error moving template code: $err"
    }

}

ad_proc -public cms::template::rename {
    -template_id:required
    -name:required
} {
    Handle the file system part of renaming a template. You must also call content::item::rename.

    @see content::item::rename
} {
    set template_root [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]
    set base_path "[acs_root_dir]/templates"
    content::item::get -item_id $template_id
    set parent_path [content::item::get_path -item_id $content_item(parent_id) -root_folder_id $template_root]
    set old_name "${base_path}/[content::template::get_path -template_id $template_id -root_folder_id $template_root]"
    set new_name "${base_path}/${parent_path}/${name}"
    if { [catch { file rename -force ${old_name}.adp ${new_name}.adp } err] } {
	ns_log debug "cms::template::rename: encountered error renaming template adp: $err"
    }
    if { [catch { file rename -force ${old_name}.tcl ${new_name}.tcl } err] } {
	ns_log debug "cms::template::rename: encountered error renaming template code: $err"
    }
}

ad_proc -public cms::template::delete {
    -template_id:required
} {
    Handle the file system part of deleting a template. You must also call content::item::delete.

    @see content::item::delete    
} {
    set template_root [cm::modules::templates::getRootFolderID [ad_conn subsite_id]]
    set base_path "[acs_root_dir]/templates"
    set template_path "${base_path}/[content::template::get_path -template_id $template_id -root_folder_id $template_root]"
    if { [catch { file delete ${template_path}.adp } err] } {
	ns_log debug "cms::template::delete: encountered error deleting template adp: $err"
    }
    if { [catch { file delete ${template_path}.tcl } err] } {
	ns_log debug "cms::template::delete: encountered error deleting template code: $err"
    }
}