<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="register_templates">      
      <querytext>
      begin
                   content_type.register_template(
                       content_type => :content_type,
	               template_id  => :template_id,
	               use_context  => :context );
                 end;
      </querytext>
</fullquery>

 
</queryset>
