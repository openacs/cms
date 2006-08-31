ad_page_contract {

    Set the default content insertion method for a content type

    @author Michael Steigman (michael@steigman.net)
    @creation-date March 2006
} {
    {content_type}
    {content_method}
    {return_url ""}
}

# default return_url
if { $return_url eq "" } {
    set return_url [export_vars -base index content_type]
}

db_exec_plsql set_content_method_default {}
#cms::type::set_content_method_default -content_type $content_type \
    -content_method $content_method
cms::type::flush_content_methods_cache $content_type

ad_returnredirect $return_url
