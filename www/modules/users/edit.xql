<?xml version="1.0"?>
<queryset>

<fullquery name="edit_group_1">      
      <querytext>
      
    update groups 
      set group_name = :group_name
      where group_id = :group_id
      </querytext>
</fullquery>

 
<fullquery name="edit_group_2">      
      <querytext>
      
    update parties
      set email = :email, url = :url
      where party_id = :group_id
      </querytext>
</fullquery>

 
</queryset>
