# content-method-procs.tcl


# @namespace content_method

# Procedures regarding content methods

namespace eval content_method {}


ad_proc content_method::get_content_methods { content_type args } {

  @public get_content_methods

  Returns a list of content_methods that are associated with 
  a content type, first checking for a default method, then for registered
  content methods, and then for all content methods

  @author Michael Pih

  @param  content_type The content type
  @option get_labels   Instead of a list of content methods, return
    a list of label-value pairs of associated content methods.
  @return A list of content methods or a list of label-value pairs of 
    content methods if the "-get_labels" option is specified
  @see {content_method::get_content_method_options, 
        content_method::text_entry_filter_sql }

} {
    template::util::get_opts $args

    if { [info exists opts(get_labels)] } {
	set methods \
		[content_method::get_content_method_options $content_type]
	return $methods
    }

    set text_entry_filter [text_entry_filter_sql $content_type]

    # get default content method (if any)
    template::query get_default_method default_method onevalue "
      select 
        content_method 
      from
        cm_content_methods m
      where
        content_method = content_method.get_method (:content_type )
      $text_entry_filter
    " -cache "content_method_types_default $content_type"
    
    # if the default exists, return it
    if { ![template::util::is_nil default_method] } {
	set methods [list $default_method]
    } else {
	# otherwise look up all content method mappings

	template::query get_methods_1 methods onelist "
	  select
	    map.content_method
	  from
	    cm_content_type_method_map map, cm_content_methods m
	  where
	    map.content_method = m.content_method
	  and
	    map.content_type = :content_type
	  $text_entry_filter
	" -cache "content_method_types $content_type"
    }

    # if there are no mappings, return all methods
    if { [template::util::is_nil methods] } {

	template::query get_methods_2 methods onelist "
	  select
	    content_method
	  from
	    cm_content_methods m
	  where 1 = 1
	  $text_entry_filter
	" -cache "content_method_types"
    }

    return $methods
}


ad_proc content_method::get_content_method_options { content_type } {

  @private get_content_method_options

  Returns a list of label, content_method pairs that are associated with 
  a content type, first checking for a default method, then for registered
  content methods, and then for all content methods

  @author Michael Pih
  @param content_type The content type
  @return A list of label, value pairs of content methods
  @see {content_method::get_content_methods,
        content_method::text_entry_filter_sql }

} {
    
    set text_entry_filter [text_entry_filter_sql $content_type]

    template::query get_content_default_method default_method onerow "
      select
        label, map.content_method
      from
        cm_content_type_method_map map, cm_content_methods m
      where
        map.content_method = m.content_method
      and
        map.content_method = content_method.get_method( :content_type )
      $text_entry_filter
    " -cache "content_method_types_n_labels_default $content_type"

    template::util::array_to_vars default_method

    if { ![template::util::is_nil content_method] } {
	set methods [list [list $label $content_method]]
    } else {
	# otherwise look up all content methods mappings
	template::query get_methods_1 methods multilist "
	  select
	    label, map.content_method
	  from
	    cm_content_methods m, cm_content_type_method_map map
	  where
            m.content_method = map.content_method
	  and
	    map.content_type = :content_type
	  $text_entry_filter
	" -cache "content_method_types_n_labels $content_type"
    }

    # if there are no mappings, return all methods
    if { [template::util::is_nil methods] } {

	template::query get_methods_2 methods multilist "
	  select
	    label, content_method
	  from
	    cm_content_methods m
	  where 1 = 1
	  $text_entry_filter
	" -cache "content_method_types_n_labels"
    }

    return $methods
}


ad_proc content_method::text_entry_filter_sql { content_type } {

  @private text_entry_filter_sql

  Generate a SQL stub that filters out the text_entry content method

  @author Michael Pih
  @param  content_type
  @return SQL stub that possibly filters out the text_entry content method

} {
    
    set text_entry_filter_sql ""

    template::query count_text_mime_types has_text_mime_type onevalue "
      select
        count(*)
      from
        cr_content_mime_type_map
      where
        mime_type like ('%text/%')
      and
        content_type = :content_type
    "

    if { $has_text_mime_type == 0 } {
	set text_entry_filter_sql \
		"and m.content_method ^= 'text_entry'"
    }

    return $text_entry_filter_sql
}



ad_proc content_method::flush_content_methods_cache { {content_type ""} } {

  @public flush_content_method_cache

  Flushes the cache for content_method_types for a given content type.  If no
  content type is specified, the entire content_method_types cache is
  flushed

  @author Michael Pih
  @param content_type The content type, default null

} {

    if { [template::util::is_nil content_type] } {

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
