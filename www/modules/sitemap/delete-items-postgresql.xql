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


<partialquery name="symlink_delete">      
      <querytext>

        content_symlink__delete

      </querytext>
</partialquery>

<partialquery name="folder_delete">      
      <querytext>

        content_folder__delete

      </querytext>
</partialquery>

<partialquery name="template_delete">      
      <querytext>

        content_template__delete

      </querytext>
</partialquery>

<partialquery name="item_delete">      
      <querytext>

        content_item__delete

      </querytext>
</partialquery>
 
</queryset>
