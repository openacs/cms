<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="symlink_delete">      
      <querytext>
      
         begin content_symlink.delete(:id); end;
      </querytext>
</fullquery>

 
</queryset>
