<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete_items">      
      <querytext>
      
	  begin
	  $delete_proc (
	    $delete_key => :del_item_id
          );
          end;
      </querytext>
</fullquery>

 
</queryset>
