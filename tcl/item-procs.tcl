ad_library {
    Helper procs for content items
}

namespace eval cms::item {}

ad_proc -public cms::item::get_id_from_revision {
    -revision_id:required
} {
    Retrieve the ID for given revision
} {

    return [db_string get_id {}]
}

ad_proc -public cms::item::has_text_content_p {
    -revision_id:required
} {
    Does this item have any text in the content DB field?
    @return boolean
} {

    return [expr [db_string get_content_length {}] > 0]
}

ad_proc -public cms::item::storage_type {
    -revision_id:required
} {
    @return string containing either "text" or "file"
} {

    return [db_string get_storage_type {} -default "text"]
}

ad_proc -public cms::item::mime_type {
    -revision_id:required
} {
    @return string containing mime type
} {

    return [db_string get_mime_type {}]
}
