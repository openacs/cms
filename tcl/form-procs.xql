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

<fullquery name="process_insert_statement">
	<querytext>
              insert into $last_table (
                [join $columns ", "]
              ) values (
                [join $values ", "]
              )"
	</querytext>
</fullquery>

</queryset>