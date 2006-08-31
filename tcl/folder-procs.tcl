ad_library {

    Procs for managing content folders

}

namespace eval cms::folder {}

ad_proc -public cms::folder::get {
    -folder_id:required
    {-revision_id "" }
    {-array_name "folder_info" }
} {
    get a folder revision

    @param folder_id             item id of the folder you want
    @return array 
    
} {

    if { $revision_id eq "" } {
	set revision_id [content::item::get_latest_revision -item_id $folder_id]
    }
    upvar $array_name local_array
    return [db_0or1row select_folder {} -column_array local_array]

}

ad_proc -public cms::folder::get_registered_types {
    { folder_id }
    { datasource multilist } 
    { name registered_types }
} {
    Get all the content types registered to a folder
    @param folder_id   The folder id
    
    @param datasource  default multilist
    Either "multilist" (return a multilist, suitable for the
			<tt>-options</tt> parameter to widgets), "multirow"
    (create a multirow datasource in the calling frame) or plain old "list". The
    multirow datasource will have two columns, <tt>pretty_name</tt>
    and <tt>content_type</tt>
    
    @param name        default registered_types
    The name for the multirow datasource. Ignored if the
    <tt>darasource</tt> parameter is not "multirow"
} {

    switch $datasource {
	multirow {
	    return [uplevel 1 "db_multirow $name not_used \"[db_map get_types_list_of_lists]\""]
	}
	multilist {
	    return [db_list_of_lists get_types_list_of_lists {}]
	}
	list {
	    return [db_list get_types_list {}]
	}
    }
}

ad_proc -public cms::folder::symlinks_allowed_p {
    -folder_id:required
} {

    Can we create symlinks in this folder?
    
    @param folder_id   The folder id
    @return boolean

} {
    return [db_string symlinks_allowed_p {} -default 0]
}