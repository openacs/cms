<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_templates">      
      <querytext>

        select content_type__register_template(
                       :content_type,
	               :template_id,
	               :context,
                       'f');
                
      </querytext>
</fullquery>

 
</queryset>
