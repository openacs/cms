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

<fullquery name="register_rel_types">      
      <querytext>

	  
          select content_type__${register_method} (
	      :content_type,
	      :target_type,
	      :relation_tag,
              :min_n,
              :max_n
          );
          

      </querytext>
</fullquery>
 
</queryset>
