ad_library {
    Helper procs for content types
}

namespace eval cms::type {}

ad_proc -public cms::type::pretty_name {
    -content_type:required
} {
    Retrieve the pretty name for given type
} {

    return [db_string get_pretty_name {}]
}

ad_proc -public cms::type::has_subtypes_p {
    -content_type:required
} {
    @return boolean
} {

    return [expr [db_string get_subtype_count {}] > 0]
}

ad_proc -public cms::type::has_mime_types_p {
    -content_type:required
} {
    Function based on code in old content_add::content_method_html proc
    which would spit out html to allow selection of content_method
    @return boolean
} {

    return [expr [db_string get_mime_type_count {}] > 0]
}

ad_proc -public cms::type::has_text_mime_types_p {
    -content_type:required
} {
    Function based on code in old content_add::content_method_html proc
    which would spit out html to allow selection of content_method
    @return boolean
} {

    return [expr [db_string get_text_mime_type_count {}] > 0]
}

ad_proc -public cms::type::get_content_methods { content_type args } {

  Returns a list of content_methods that are associated with 
  a content type, first checking for a default method, then for registered
  content methods, and then for all content methods

  @author Michael Pih

  @param  content_type The content type
  @option get_labels   Instead of a list of content methods, return
    a list of label-value pairs of associated content methods.
  @return A list of content methods or a list of label-value pairs of 
    content methods if the "-get_labels" option is specified

  @see cms::type::get_content_method_options
  @see cms::type::text_entry_filter_sql

} {
    template::util::get_opts $args

    if { [info exists opts(get_labels)] } {
	set methods \
		[cms::type::get_content_method_options $content_type]
	return $methods
    }

    set text_entry_filter [text_entry_filter_sql $content_type]

    # get default content method (if any)
    set default_method [db_string get_default_method ""]
    
    # if the default exists, return it
    if { ![template::util::is_nil default_method] } {
	set methods [list $default_method]
    } else {
	# otherwise look up all content method mappings

        set methods [db_list get_methods_1 ""]
    }

    # if there are no mappings, return all methods
    if { [template::util::is_nil methods] } {

        set methods [db_list get_methods_2 ""]
    }

    return $methods
}


ad_proc -private cms::type::get_content_method_options { content_type } {

  Returns a list of label, content_method pairs that are associated with 
  a content type, first checking for a default method, then for registered
  content methods, and then for all content methods

  @author Michael Pih
  @param content_type The content type
  @return A list of label, value pairs of content methods

  @see cms::type::get_content_methods
  @see cms::type::text_entry_filter_sql

} {
    
    set text_entry_filter [text_entry_filter_sql $content_type]

    db_0or1row get_content_default_method ""

    if { ![template::util::is_nil content_method] } {
	set methods [list [list $label $content_method]]
    } else {
	# otherwise look up all content methods mappings
        set methods [db_list_of_lists get_methods_1 ""]
    }

    # if there are no mappings, return all methods
    if { [template::util::is_nil methods] } {

        set methods [db_list_of_lists get_methods_2 ""]
    }

    return $methods
}


ad_proc -private cms::type::text_entry_filter_sql { 
    content_type 
} {

  Generate a SQL stub that filters out the text_entry content method

  @author Michael Pih
  @param  content_type mime type 

  @return SQL stub that possibly filters out the text_entry content method

} {
    
    set text_entry_filter_sql ""

    set has_text_mime_type [db_string count_text_mime_types ""]

    if { $has_text_mime_type == 0 } {
	set text_entry_filter_sql \
		"and m.content_method <> 'text_entry'"
    }

    return $text_entry_filter_sql
}



ad_proc -public cms::type::flush_content_methods_cache { 
    {content_type ""} 
} {

  Flushes the cache for content_method_types for a given content type.  If no
  content type is specified, the entire content_method_types cache is
  flushed

  @author Michael Pih
  @param content_type The content type, default null

} {

    if { [template::util::is_nil content_type] } {
        # FIXME: figure out what to do with these after template::query calls
        # are gone.

	# flush the entire content_method_types cache
	template::query::flush_cache "content_method_types*"
    } else {

	# flush the content_method_types cache for a content type
	# 1) flush the default method cache 
	template::query::flush_cache \
		"content_method_types_default $content_type"
	template::query::flush_cache \
		"content_method_types_n_labels_default $content_type"

	# 2) flush the mapped methods cache
	template::query::flush_cache "content_method_types ${content_type}*"

	# 3) flush the all methods cache
	template::query::flush_cache "content_method_types"
	template::query::flush_cache "content_method_types_n_labels"
    }
}

ad_proc -public cms::type::set_content_method_default { 
    -content_type:required
    -content_method:required
} {

  @author Michael Steigman
  @param content_type The content type
  @param content_method The new default content method 

} {

    return [package_exec_plsql -var_list [list [list content_type $content_type] [list content_method $content_method]] \
		content_method set_default_method]
}

ad_proc -public cms::type::unset_content_method_default { 
    -content_type:required
} {

  @author Michael Steigman
  @param content_type The content type
  @return integer
} {

    return [package_exec_plsql -var_list [list [list content_type $content_type]] \
		content_method unset_default_method]
}

ad_proc -public cms::type::remove_content_method { 
    -content_type:required
    -content_method:required
} {

  @author Michael Steigman
  @param content_type The content type
  @param content_type The method to remove
  @return integer
} {

    return [package_exec_plsql -var_list [list [list content_type $content_type] [list content_method $content_method] \
		content_method remove_method]
}

ad_proc -public cms::type::add_content_method { 
    -content_type:required
    -content_method:required
} {

  @author Michael Steigman
  @param content_type The content type
  @param content_type The method to add
  @return integer
} {

    return [package_exec_plsql -var_list [list [list content_type $content_type] [list content_method $content_method] \
		content_method add_method]
}

ad_proc -public cms::type::add_all_content_methods { 
    -content_type:required
} {

  @author Michael Steigman
  @param content_type The content type
  @return integer
} {

    return [package_exec_plsql -var_list [list [list content_type $content_type]] \
		content_method add_all_methods]
}

ad_proc -public cms::type::content_method_is_mapped_p { 
    -content_type:required
    -content_method:required
} {

  @author Michael Steigman
  @param content_type The content type
  @param content_type The method to check
  @return integer
} {

    return [package_exec_plsql -var_list [list [list content_type $content_type] [list content_method $content_method] \
		content_method is_mapped]
}

ad_proc -public cms::type::get_content_method { 
    -content_type:required
} {

  @author Michael Steigman
  @param content_type The content type
  @return integer
} {

    return [package_exec_plsql -var_list [list [list content_type $content_type] \
		content_method get_method]
}
