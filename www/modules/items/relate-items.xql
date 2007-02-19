<?xml version="1.0"?>
<queryset>

<fullquery name="cr_item_rel_tag_options">      
      <querytext>
        select relation_tag 
          from cr_type_relations 
         where content_type = :content_type 
           and target_type = :target_type  
      </querytext>
</fullquery>

<fullquery name="cr_item_child_rel_tag_options">      
      <querytext>
        select relation_tag 
          from cr_type_children
         where parent_type = :content_type 
           and child_type = :child_type  
      </querytext>
</fullquery>

 
</queryset>
