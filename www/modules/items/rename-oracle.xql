<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rename_item">      
      <querytext>
      
    begin 
    content_item.rename (
        item_id => :item_id, 
        name    => :name 
    ); 
    end;
      </querytext>
</fullquery>

 
</queryset>
