<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_widget">      
      <querytext>

        select cm_form_widget__register_attribute_widget(
              :content_type,
              :attribute_name,
              :widget,
              :is_required
          );
	 
      </querytext>
</fullquery>

 
</queryset>
