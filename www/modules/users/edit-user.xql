<?xml version="1.0"?>
<queryset>

<fullquery name="edit_user_1">      
      <querytext>
      
    update users $users_update where user_id = :item_id
  
      </querytext>
</fullquery>

 
<fullquery name="edit_user_2">      
      <querytext>
      
    update persons set first_names=:first_names, last_name = :last_name 
      where person_id=:item_id
  
      </querytext>
</fullquery>

 
<fullquery name="edit_user_3">      
      <querytext>
      
    update parties set email=:email, url=:url where party_id = :item_id
  
      </querytext>
</fullquery>

 
</queryset>
