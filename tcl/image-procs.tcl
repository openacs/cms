ad_library {
    Helper procs for images
}

namespace eval cms::image {}

ad_proc -public cms::image::get {
    -image_id:required
    {-revision_id "" }
    {-array_name "content_item" }
} {
    get a template revision

    @param template_id             item id of the template you want
    @return array 
    
} {

    if { $revision_id eq "" } {
	set revision_id [content::item::get_latest_revision -item_id $image_id]
    }
    upvar $array_name local_array
    return [db_0or1row select_image {} -column_array local_array]

}
