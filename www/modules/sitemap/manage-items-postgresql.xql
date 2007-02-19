<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_marked">      
      <querytext>
      
	select content_item__get_title(item_id, 'f') as title, 
	       '/' || content_item__get_path(item_id,:root_id) as path, 
	       item_id, parent_id
	  from cr_items
	 where item_id in ([join $clip_items ","])
	    -- only for those items which user has write privs (MS- this should be moved)
	   and acs_permission__permission_p(item_id, :user_id, 'write') = 't'

      </querytext>
</fullquery>

</queryset>
