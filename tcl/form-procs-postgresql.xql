<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<partialquery name="content::query_form_metadata.attributes_query_1">      
	<querytext>
		
    select
      attributes.attribute_id, attribute_name, 
      attributes.table_name,
      attribute_label, type_label, object_type as subtype, datatype, 
      params.is_html, params.is_required,
      widget, param,
      coalesce( (select param_type from cm_attribute_widget_params
                 where attribute_id = attributes.attribute_id
                 and param_id = params.param_id), 'literal' ) param_type, 
      coalesce( (select param_source from cm_attribute_widget_params
                 where attribute_id = attributes.attribute_id
                 and param_id = params.param_id), 'onevalue' ) param_source, 
      coalesce( (select value from cm_attribute_widget_params
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
          acs_attributes attr RIGHT OUTER JOIN,
          (
            select 
              o2.object_type, o2.pretty_name, tree_level(o2.tree_sortkey) as tree_level,
              o2.table_name
            from
               (
                 SELECT *
                 FROM acs_object_types
                 WHERE object_type = :content_type
               ) o1, acs_object_types o2
            where 
              o2.object_type <> 'acs_object'
            AND
              o2.tree_sortkey <= o1.tree_sortkey
            AND
              o1.tree_sortkey like (o2.tree_sortkey || '%')

          ) types USING (object_type)
      ) attributes
    where
      attributes.attribute_id = params.attribute_id

	</querytext>
</fullquery>

<partialquery name="content::create_form_element.cfe_attribute_name_to_char">
	<querytext>

	to_char($attribute_name, 'YYYY MM DD HH24 MI SS') 
                   as $attribute_name

	</querytext>
</partialquery>

<fullquery name="content::create_form_element.get_revision_id">
	<querytext>
	select content_item__get_latest_revision(:item_id)
	</querytext>
</fullquery>

<partialquery name="content::get_revision_create_element.get_enum_1">
	<querytext>
	select coalesce(pretty_name,enum_value), enum_value
	from acs_enum_values
	where attribute_id = :attribute_id
	order by sort_order
	</querytext>
</partialquery>

<fullquery name="content::process_revision_form.new_content_revision">
	<querytext>

	     select content_revision__new(:title,:description,:mime_type,' ',content_symlink__resolve(:item_id),'[ns_conn peeraddr]',[User::getID]) as revision_id

	</querytext>
</fullquery>

<fullquery name="content::process_revision_form.get_extended_attributes">
	<querytext>

	  select 
            types.table_name, types.id_column, attr.attribute_name,
            attr.datatype
          from 
            acs_attributes attr RIGHT OUTER JOIN
            ( select 
                o2.object_type, o2.table_name, o2.id_column,
		tree_level(o2.tree_sortkey) as inherit_level
              from
		( SELECT *
		  FROM acs_object_types
		  WHERE object_type = :content_type
		) o1,
                acs_object_types o2
              where
		o2.object_type <> 'acs_object'
	      AND
		o2.object_type <> 'content_revision'
	      AND
		o2.tree_sortkey <= o1.tree_sortkey
	      AND
		o1.tree_sortkey like (o2.tree_sortkey || '%')

	    ) types USING (object_type)
          order by 
            types.inherit_level desc

	</querytext>

</fullquery>

<partialquery name="content::insert_element_data.ied_get_objects_tree">
	<querytext>

          select 
            types.table_name, types.id_column, attr.attribute_name,
            attr.datatype
          from 
            acs_attributes attr,
            ( select 
                o2.object_type, o2.table_name, o2.id_column,
		tree_level(o2.tree_sortkey) as inherit_level
              from
		( SELECT *
		  FROM acs_object_types
		  WHERE object_type = :content_type
		) o1,
		acs_object_types o2
              where 
                object_type not in ($sql_exclusion)
	      and
		o2.tree_sortkey <= o1.tree_sortkey
	      and
		o1.tree_sortkey like (o2.tree_sortkey || '%')

	    ) types USING (object_type)

	</querytext>
</partialquery>

<partialquery name="content::new_item.cont_new_item_non_null_params">
	<querytext>
	:$param
	</querytext>

</partialquery>

<partialquery name="content::new_item.cont_new_item_def_params">
	<querytext>
	$defArray($param)
	</querytext>
</partialquery>

<partialquery name="content::new_item.cont_new_item_rel_tag">
	<querytext>
null
	</querytext>
</partialquery>

<fullquery name="content::new_item.create_new_content_item">
	<querytext>
          select content_item__new( [join $params ","] ) as item_id
        </querytext>
</fullquery>

<fullquery name="content::upload_content.update_cr_revisions">
	<querytext>

      update cr_revisions 
      set content = [set __lob_id [db_string get_id "select empty_lob()"]]
      where revision_id = :revision_id

	</querytext>
</fullquery>

<partialquery name="content::get_sql_value.string_to_timestamp">
	<querytext>

	to_date(:$name, 'YYYY MM DD HH24 MI SS')

	</querytext>
</partialquery>

<fullquery name="content::add_child_relation_element.get_all_valid_relation_tags">
	<querytext>

    select 
      relation_tag as label, relation_tag as value 
    from 
      cr_type_children c
    where
      content_item__is_subclass(:parent_type, c.parent_type) = 't'
    and
      content_item__is_subclass(:content_type, c.child_type) = 't'
    and
      content_item__is_valid_child(:parent_id, c.child_type) = 't'

	</querytext>
</fullquery>

<fullquery name="content::add_child_relation_element.get_parent_title">
	<querytext>

      select content_item__get_title(:parent_id)

	</querytext>
</fullquery>

<partialquery name="content::set_attribute_values.timestamp_to_string">
	<querytext>

	to_char($attr, 'YYYY MM DD HH24 MI SS') as $attr

	</querytext>
</partialquery>

<fullquery name="content::get_content_value.gcv_get_revision_id">
	<querytext>

	    select content_revision__to_temporary_clob(:revision_id) as revision_id;

	</querytext>
</fullquery>

<fullquery name="content::get_attributes.ga_get_attributes">
	<querytext>

    select
      [join $args ","]
    from
      acs_attributes,
      (
 	select 
	  o2.object_type as ancestor, tree_level(o2.tree_sortkey) as type_order
	from
	  (
	    SELECT *
	    FROM acs_object_types
	    WHERE object_type = :content_type
	  ) o1, acs_object_types o2
	where
	  o2.tree_sortkey <= o1.tree_sortkey
	AND
	  o1.tree_sortkey like (o2.tree_sortkey || '%')

      ) types
    where
      object_type = ancestor
    and
      attribute_name <> 'ldap dn'
    order by type_order desc, sort_order

	</querytext>
</fullquery>

<fullquery name="content::get_attribute_enum_values.gaev_get_enum_values">
	<querytext>

           select
	     coalesce(pretty_name,enum_value), 
	     enum_value
	   from
	     acs_enum_values
	   where
	     attribute_id = :attribute_id
	   order by
	     sort_order

	</querytext>
</fullquery>

<fullquery name="content::get_latest_revision.glr_get_latest_revision">
	<querytext>

    select content_item__get_latest_revision(:item_id)

	</querytext>
</fullquery>

<partialquery name="content::add_basic_revision.abr_new_revision_title">
	<querytext>

   select content_revision__new(:title

	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_description">
	<querytext>
         , :description
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_publish_date">
	<querytext>
         , :publish_date
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_mime_type">
	<querytext>
         , :mime_type
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_nls_language">
	<querytext>
         , :nls_language
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_text">
	<querytext>
         , :text
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_description_ne">
	<querytext>
         , null
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_publish_date_ne"
	<querytext>
         , now()
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_mime_type_ne">
	<querytext>
         , 'text/plain'
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_nls_language_ne">
	<querytext>
         , null
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_text_ne">
	<querytext>
         , ' '
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_end_items">
	<querytext>
         , content_symlink__resolve(:item_id), :revision_id, now(), :creation_ip, :creation_user) as revision_id
	</querytext>
</partialquery>

<fullquery name="content::update_content_from_file.upcff_update_cr_revisions">
	<querytext>

    update cr_revisions 
    set content = [set __lob_id [db_string get_id "select empty_lob()"]]
    where revision_id = :revision_id

	</querytext>
</fullquery>

<fullquery name="content::copy_content.cc_copy_content">
	<querytext>

          select content_revision__content_copy (:revision_id_src, :revision_id_dest)

	</querytext>
</fullquery>

</queryset>
