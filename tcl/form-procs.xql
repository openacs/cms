<?xml version="1.0"?>
<queryset>

<fullquery name="get_content_type">      
	<querytext>
	select content_type from cr_items i, cr_revisions r
	where r.item_id = i.item_id
	and   r.revision_id = :revision_id
	</querytext>

</fullquery>

<partialquery name="cfe_attribute_name">
	<querytext>

	$attribute_name

	</querytext>

</partialquery>

<fullquery name="get_element_value">      
	<querytext>
	select $what from ${table_name}x where revision_id = :revision_id
	</querytext>
</fullquery>

<fullquery name="insert_revision_form">
	<querytext>
              insert into $last_table (
                [join $columns ", "]
              ) values (
                [join $values ", "]
              )"
	</querytext>
</fullquery>

<partialquery name="ied_get_objects_tree_extra_where">
	<querytext>

	 and $extra_where

	</querytext>
</partialquery>

<partialquery name="ied_get_objects_tree_order_by">
	<querytext>

          order by 
            types.inherit_level desc

	</querytext>
</partialquery>

<fullquery name="process_insert_statement">
	<querytext>
              insert into $last_table (
                [join $columns ", "]
              ) values (
                [join $values ", "]
              )"
	</querytext>
</fullquery>

<fullquery name="addrev_get_content_type">
	<querytext>
    select object_type content_type, table_name
    from acs_object_types
    where object_type = (select content_type from cr_items 
                         where item_id = :item_id)
	</querytext>
</fullquery>

<fullquery name="update_mime_sql">
	<querytext>

      update cr_revisions 
        set mime_type = :mime_type 
        where revision_id = :revision_id

	</querytext>
</fullquery>

<fullquery name="get_text_mime_types">
	<querytext>

	    select
	      label, map.mime_type as value
	    from
	      cr_mime_types types, cr_content_mime_type_map map
	    where
	      types.mime_type = map.mime_type
	    and
	      map.content_type = :content_type
	    and
	      lower(types.mime_type) like ('text/%')
	    order by
	      label

	</querytext>
</fullquery>

<fullquery name="get_parent_type">
	<querytext>

    select content_type from cr_items 
    where item_id = :parent_id

	</querytext>
</fullquery>

<fullquery name="set_content_values">
	<querytext>

	$param(value)

	</querytext>
</fullquery>

<fullquery name="gtap_get_attribute_data">
	<querytext>

    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext x
    where
      object_type in ( [join $in_list ","] )

	</querytext>
</fullquery>

<fullquery name="gap_get_attribute_data">
	<querytext>

    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext
    where
      object_type = :content_type
    and
      attribute_name = :attribute_name

	</querytext>
</fullquery>

<fullquery name="get_previous_version_values">
	<querytext>

    select 
      [join $columns ", "] 
    from 
      [get_type_info $content_type table_name]x
    where 
      revision_id = :revision_id

	</querytext>
</fullquery>

<fullquery name="count_mime_type">
	<querytext>

	select count(*) from cr_content_mime_type_map
	where content_type = :content_type and mime_type like 'text/%'

	</querytext>
</fullquery>

<fullquery name="get_type_info_1">
	<querytext>

      select 
        $ref
      from 
        acs_object_types 
      where 
        object_type = :object_type

	</querytext>
</fullquery>

<fullquery name="get_type_info_2">
	<querytext>

      select 
        [join $args ","]
      from 
        acs_object_types 
      where 
        object_type = :object_type

	</querytext>
</fullquery>

</queryset>