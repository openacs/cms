<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_target_types">      
      <querytext>


  select
    lpad(' ', tree_level(tree_sortkey), '-') || pretty_name, object_type
  from
    acs_object_types
  where tree_sortkey like (select tree_sortkey || '%' 
                             from acs_object_types 
                            where object_type = 'content_revision')

      </querytext>
</fullquery>

 
</queryset>
