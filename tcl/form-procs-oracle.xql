<?xml version="1.0"?>
<queryset>

<partialquery name="content::query_form_metadata.attributes_query_1">      
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

<partialquery name="content::create_form_element.cfe_attribute_name_to_char">
	<querytext>

	to_char($attribute_name, 'YYYY MM DD HH24 MI SS') 
                   as $attribute_name

	</querytext>
</partialquery>


<fullquery name="content::create_form_element.get_revision_id">
	<querytext>
	select content_item.get_latest_revision(:item_id) from dual
	</querytext>
</fullquery>

<partialquery name="content::get_revision_create_element.get_enum_1">
	<querytext>
	select nvl(pretty_name,enum_value), enum_value
	from acs_enum_values
	where attribute_id = :attribute_id
	order by sort_order
	</querytext>
</partialquery>

<fullquery name="content::process_revision_form.new_content_revision">
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

<fullquery name="content::process_revision_form.get_extended_attributes">
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

<partialquery name="content::insert_element_data.ied_get_objects_tree">
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

<partialquery name="content::new_item.cont_new_item_non_null_params">
	<querytext>
	$param => :$param
	</querytext>
</partialquery>

<partialquery name="content::new_item.cont_new_item_def_params">
	<querytext>
	$param => $defArray($param)
	</querytext>
</partialquery>

<partialquery name="content::new_item.cont_new_item_rel_tag">
	<querytext>
	relation_tag => :relation_tag
	</querytext>
</partialquery>

<fullquery name="content::new_item.create_new_content_item">
	<querytext>
        begin 
          :item_id := content_item.new( [join $params ","] );
        end;
        </querytext>
</fullquery>

<fullquery name="content::upload_content.update_cr_revisions">
	<querytext>

      update cr_revisions 
      set content = empty_blob() where revision_id = :revision_id
      returning content into :1

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
      content_item.is_subclass(:parent_type, c.parent_type) = 't'
    and
      content_item.is_subclass(:content_type, c.child_type) = 't'
    and
      content_item.is_valid_child(:parent_id, c.child_type) = 't'

	</querytext>
</fullquery>

<fullquery name="content::add_child_relation_element.get_parent_title">
	<querytext>

      select content_item.get_title(:parent_id) from dual

	</querytext>
</fullquery>

<partialquery name="content::set_attribute_values.timestamp_to_string">
	<querytext>

	to_char($attr, 'YYYY MM DD HH24 MI SS') as $attr

	</querytext>
</partialquery>

<fullquery name="content::get_content_value.gcv_get_revision_id">
	<querytext>

	  begin
	    content_revision.to_temporary_clob(:revision_id);
	  end;

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
	  object_type ancestor, level as type_order
	from 
	  acs_object_types
	connect by 
	  prior supertype = object_type
	start with 
          object_type = :content_type
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
	     nvl(pretty_name,enum_value), 
	     enum_value
	   from
	     acs_enum_values
	   where
	     attribute_id = :attribute_id
	   order by
	     sort_order

	</querytex>
</fullquery>

<fullquery name="content::get_latest_revision.glr_get_latest_revision">
	<querytext>

    select content_item.get_latest_revision(:item_id) from dual

	</querytext>
</fullquery>

<partialquery name="content::add_basic_revision.abr_new_revision_title">
	<querytext>

begin :revision_id := content_revision.new(
         title         => :title
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_description">
	<querytext>
         , description         => :description
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_publish_date">
	<querytext>
         , publish_date         => :publish_date
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_mime_type">
	<querytext>
         , mime_type         => :mime_type
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_nls_language">
	<querytext>
         , nls_language         => :nls_language
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_text">
	<querytext>
         , text         => :text
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_description_ne">
	<querytext>
         , description         => null
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_publish_date_ne">
	<querytext>
         , publish_date         => sysdate
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_mime_type_ne">
	<querytext>
         , mime_type         => 'text/plain'
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_nls_language_ne">
	<querytext>
         , nls_language         => null
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_text_ne">
	<querytext>
         , text         => ' '
	</querytext>
</partialquery>

<partialquery name="content::add_basic_revision.abr_new_revision_end_items">
	<querytext>
       , item_id       => content_symlink.resolve(:item_id),
         revision_id   => :revision_id,
         creation_date  => sysdate,
         creation_ip   => :creation_ip,
         creation_user => :creation_user
      ); end;
	</querytext>
</partialquery>

<fullquery name="content::update_content_from_file.upcff_update_cr_revisions">
	<querytext>

    update cr_revisions 
    set content = empty_blob() where revision_id = :revision_id
    returning content into :1

	</querytext>
</fullquery>

<fullquery name="content::copy_content.cc_copy_content">
	<querytext>

           begin
             content_revision.content_copy (
              revision_id      => :revision_id_src,
              revision_id_dest => :revision_id_dest
             );
           end;

	</querytext>
</fullquery>

</queryset>
