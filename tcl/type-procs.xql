<?xml version="1.0"?>
<queryset>

	<fullquery name="cms::type::pretty_name.get_pretty_name">
		<querytext>
			select pretty_name from acs_object_types where object_type = :content_type
		</querytext>
	</fullquery>

	<fullquery name="cms::type::has_subtypes_p.get_subtype_count">
		<querytext>
			select count(*) from acs_object_types where supertype = :content_type
	      </querytext>
	</fullquery>

	<fullquery name="cms::type::has_mime_types_p.get_mime_type_count">
		<querytext>
			select count(*)
			  from cr_content_mime_type_map
			 where content_type = :content_type
		</querytext>
	</fullquery>

	<fullquery name="cms::type::has_text_mime_types_p.get_text_mime_type_count">
		<querytext>
			select count(*)
			  from cr_content_mime_type_map
			 where mime_type like ('%text/%')
			   and content_type = :content_type
		</querytext>
	</fullquery>

	<fullquery name="cms::type::text_entry_filter_sql.count_text_mime_types">
		<querytext>
			select count(*)
			  from cr_content_mime_type_map
			 where mime_type like ('%text/%')
			   and content_type = :content_type
		</querytext>
	</fullquery>

	<fullquery name="cms::type::get_content_methods.get_methods_1">
		<querytext>
			select map.content_method
			  from cm_content_type_method_map map, cm_content_methods m
			 where map.content_method = m.content_method
			   and map.content_type = :content_type
			   $text_entry_filter
		</querytext>
	</fullquery>

	<fullquery name="cms::type::get_content_methods.get_methods_2">
		<querytext>
			select content_method
			  from cm_content_methods m
			 where 1 = 1
			 $text_entry_filter
		</querytext>
	</fullquery>

	<fullquery name="cms::type::get_content_method_options.get_methods_1"> 
		<querytext>
			select label, map.content_method
			  from cm_content_methods m, cm_content_type_method_map map
			 where m.content_method = map.content_method
			   and map.content_type = :content_type
			   $text_entry_filter
	      </querytext>
	</fullquery>
 
	<fullquery name="cms::type::get_content_method_options.get_methods_2">
		<querytext>
			select label, content_method
			  from cm_content_methods m
			 where 1 = 1
			 $text_entry_filter
		</querytext>
	</fullquery>

</queryset>

