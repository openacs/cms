<?xml version="1.0"?>
<queryset>


 
<fullquery name="check_registered">      
      <querytext>
      
      select 1
      from
        cm_attribute_widgets
      where
        attribute_id = :attribute_id
      and
        widget = :widget
    
      </querytext>
</fullquery>

 
</queryset>
