<?xml version="1.0"?>
<queryset>

<fullquery name="update_widgets">      
      <querytext>
      
	  update cm_attribute_widgets
            set is_required = case when is_required = 't' then 'f' else 't' end
            where attribute_id = :attribute_id
            and widget = :widget
      </querytext>
</fullquery>

 
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
