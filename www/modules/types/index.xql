<?xml version="1.0"?>
<queryset>

<fullquery name="get_module_id">      
      <querytext>
      
  select module_id from cm_modules where key = 'types' and package_id = :package_id

      </querytext>
</fullquery>

 
<fullquery name="get_object_type">      
      <querytext>
      
  select 
    pretty_name
  from
    acs_object_types
  where
    object_type = :content_type

      </querytext>
</fullquery>

 
</queryset>
