<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="new_keyword">      
      <querytext>

    select content_keyword__new(
      :heading, 
      :description, 
      null,
      :keyword_id,
      now(),
      :user_id,
      :ip$pid,
      'content_keyword');

      </querytext>
</fullquery>

 
<fullquery name="get_keyword_id">      
      <querytext>
      
    select acs_object_id_seq.nextval 
  
      </querytext>
</fullquery>

 
</queryset>
