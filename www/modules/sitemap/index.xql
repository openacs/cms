<?xml version="1.0"?>
<queryset>

<fullquery name="get_module_name">      
      <querytext>
      
  select name from cm_modules 
   where key = 'sitemap' 
     and package_id = 
     (select package_id from cms_subsite_package_map
       where subsite_id = :subsite_id)         
  
      </querytext>
</fullquery>

 
<fullquery name="get_reg_types">      
      <querytext>
      
    select
      content_type
    from
      cr_folder_type_map
    where
      folder_id = :root_id
  
      </querytext>
</fullquery>


 
<fullquery name="get_types">      
      <querytext>
      
    select
      content_type
    from
      cr_folder_type_map
    where
      folder_id = :folder_id
  
      </querytext>
</fullquery>

 
</queryset>
