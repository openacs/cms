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

<partialquery name="symlink_delete">      
      <querytext>

        content_symlink.delete

      </querytext>
</partialquery>

<partialquery name="folder_delete">      
      <querytext>

        content_folder.delete

      </querytext>
</partialquery>

<partialquery name="template_delete">      
      <querytext>

        content_template.delete

      </querytext>
</partialquery>

<partialquery name="item_delete">      
      <querytext>

        content_item.delete

      </querytext>
</partialquery>

</queryset>
