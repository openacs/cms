<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="grant_permissions">      
      <querytext>

	declare
          v_module      record;
          item_row      record;
	begin
  
	  for item_row in 
	    select item_id from cr_items
            where tree_sortkey like (select tree_sortkey || '%'
                                     from cr_items where parent_id = 0)
          LOOP 
	    PERFORM acs_permission__grant_permission (
	        item_row.item_id, 
	        :user_id, 
	        'cm_admin'
	    );
	  end loop;

	  for v_module in
	    select module_id from cm_modules
          LOOP
	    PERFORM acs_permission__grant_permission (
	        v_module.module_id,
	        :user_id,
	        'cm_admin'
            );
	  end loop;

          return null;
	end;
	
      </querytext>
</fullquery>

 
<fullquery name="get_user_id">      
      <querytext>
      
      select acs_object_id_seq.nextval 
    
      </querytext>
</fullquery>

 
</queryset>
