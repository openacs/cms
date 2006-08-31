# /cms/www/modules/types/content-method-unset-default.tcl
#
# Unset the default content insertion method for a given content type


request create
request set_param content_type   -datatype keyword
request set_param return_url     -datatype text -value ""

# default return_url
if { [template::util::is_nil return_url] } {
    set return_url [export_vars -base index content_type]
}


db_transaction {
    db_exec_plsql unset_content_method_default {}
}

cms::type::flush_content_methods_cache $content_type

ad_returnredirect $return_url
