<?xml version="1.0"?>
<queryset>

<fullquery name="get_results">      
      <querytext>
      
    select * from ($sql_query) 
    where row_index >= :start_row and row_index < (:start_row + :rows_per_page)
    order by search_score desc, title
  
      </querytext>
</fullquery>

 
</queryset>
