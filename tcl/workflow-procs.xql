<?xml version="1.0"?>
<queryset>

<fullquery name="cms::workflow::get_authors::get_assignees">
      <querytext>
	select member_id from group_approved_member_map 
   	 where rel_type = 'author_rel' 
	   and group_id = :app_group
      </querytext>
</fullquery>

<fullquery name="cms::workflow::get_editors::get_assignees">
      <querytext>
	select member_id from group_approved_member_map 
   	 where rel_type = 'editor_rel' 
	   and group_id = :app_group
      </querytext>
</fullquery>

<fullquery name="cms::workflow::get_publishers::get_assignees">
      <querytext>
	select member_id from group_approved_member_map 
   	 where rel_type = 'publisher_rel' 
	   and group_id = :app_group
      </querytext>
</fullquery>

</queryset>
