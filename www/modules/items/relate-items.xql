<?xml version="1.0"?>
<queryset>

<fullquery name="cr_item_rel_tag_options">      
      <querytext>
        select relation_tag 
          from cr_type_relations 
         where content_type = :item_type 
           and target_type = :object_type
      </querytext>
</fullquery>

<fullquery name="cr_item_child_rel_tag_options">      
      <querytext>
        select relation_tag 
          from cr_type_children
         where parent_type = :item_type 
           and child_type = :object_type
      </querytext>
</fullquery>

 
</queryset>
