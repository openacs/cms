<?xml version="1.0"?>
<queryset>

<fullquery name="get_info2">      
      <querytext>
      
    select
      party_id group_id, 'All Users' as group_name, 
      email, url, 'f' as is_empty
    from
      parties
    where
      party_id = -1
  
      </querytext>
</fullquery>

 
</queryset>
