<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_target_types">      
      <querytext>
      
  select
    lpad(' ', level, '-') || pretty_name, object_type
  from
    acs_object_types
  connect by
    prior object_type = supertype
  start with
    object_type = 'content_revision'

      </querytext>
</fullquery>

 
</queryset>
