<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="delete_items">      
      <querytext>


	 
	  select $delete_proc (
	    :del_item_id
          );

         
      </querytext>
</fullquery>

 
</queryset>
