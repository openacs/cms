<?xml version="1.0"?>
<queryset>

<partialquery name="attributes_query_1">      
	<querytext>
		
    select
      attributes.attribute_id, attribute_name, 
      attributes.table_name,
      attribute_label, type_label, object_type as subtype, datatype, 
      params.is_html, params.is_required,
      widget, param,
      nvl( (select param_type from cm_attribute_widget_params
            where attribute_id = attributes.attribute_id
            and param_id = params.param_id), 'literal' ) param_type, 
      nvl( (select param_source from cm_attribute_widget_params
            where attribute_id = attributes.attribute_id
            and param_id = params.param_id), 
           'onevalue' ) param_source, 
      nvl( (select value from cm_attribute_widget_params
            where attribute_id = attributes.attribute_id
            and param_id = params.param_id), 
           params.default_value ) value
    from
      (
        select
          aw.attribute_id, fwp.param,
          aw.widget, decode(aw.is_required,'t','t',fwp.is_required) is_required,
          fwp.param_id, fwp.default_value, fwp.is_html
        from
          cm_form_widget_params fwp, cm_attribute_widgets aw
        where
          fwp.widget = aw.widget
      ) params,
      (
        select
          attr.attribute_id, attribute_name, sort_order, 
          attr.pretty_name as attribute_label, attr.datatype, 
          types.object_type, types.pretty_name as type_label, 
          tree_level, types.table_name
        from
          acs_attributes attr,
          (
            select 
              object_type, pretty_name, level as tree_level,
              table_name
            from 
              acs_object_types
            where 
              object_type <> 'acs_object'
            connect by 
              prior supertype = object_type
            start with 
              object_type = :content_type
          ) types
        where
          attr.object_type = types.object_type
      ) attributes
    where
      attributes.attribute_id = params.attribute_id

	</querytext>
</partialquery>

<partialquery name="cfe_attribute_name_to_char">
	<querytext>

	to_char($attribute_name, 'YYYY MM DD HH24 MI SS') 
                   as $attribute_name

	</querytext>
</partialquery>

<partialquery name="attributes_query_extra_where">
	<querytext>

	 and $extra_where

	</querytext>
</partialquery>

<fullquery name="get_revision_id">
	<querytext>
	select content_item.get_latest_revision(:item_id) from dual
	</querytext>
</fullquery>

<partialquery name="get_enum_1">
	<querytext>
	select nvl(pretty_name,enum_value), enum_value
	from acs_enum_values
	where attribute_id = :attribute_id
	order by sort_order
	</querytext>
</partialquery>

<fullquery name="new_content_revision">
	<querytext>
             begin
	     :revision_id := content_revision.new(
                 title         => :title,
                 description   => :description,
                 mime_type     => :mime_type,
                 text          => ' ',
                 item_id       => content_symlink.resolve(:item_id),
                 creation_ip   => '[ns_conn peeraddr]',
                 creation_user => [User::getID]
             );
             end;
	</querytext>
</fullquery>

<fullquery name="get_extended_attributes">
	<querytext>

	  select 
            types.table_name, types.id_column, attr.attribute_name,
            attr.datatype
          from 
            acs_attributes attr,
            ( select 
                object_type, table_name, id_column, level as inherit_level
              from 
                acs_object_types
              where 
                object_type <> 'acs_object'
              and
                object_type <> 'content_revision'
              connect by 
                prior supertype = object_type
              start with 
                object_type = :content_type) types        
          where 
            attr.object_type (+) = types.object_type
          order by 
            types.inherit_level desc

	</querytext>
</fullquery>

<partialquery name="ied_get_objects_tree">
	<querytext>

          select 
            types.table_name, types.id_column, attr.attribute_name,
            attr.datatype
          from 
            acs_attributes attr,
            ( select 
                object_type, table_name, id_column, level as inherit_level
              from 
                acs_object_types
              where 
                object_type not in ($sql_exclusion)
              connect by 
                prior supertype = object_type
              start with 
                object_type = :content_type) types        
          where 
            attr.object_type (+) = types.object_type

	</querytext>
</partialquery>

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

</queryset>