<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_template">      
      <querytext>
      
      begin 
        content_template.delete(:template_id); 
      end;
      </querytext>
</fullquery>

 
</queryset>
