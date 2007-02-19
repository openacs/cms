<?xml version="1.0"?>
<queryset>

<fullquery name="cms::rel::sort_related_item_order.get_related_items">      
      <querytext>
      
            select
              rel_id
            from
              cr_item_rels
            where
              item_id = :item_id
            order by
              order_n, rel_id
        
      </querytext>
</fullquery>


<fullquery name="cms::rel::sort_related_item_order.reorder">      
      <querytext>
  	        update cr_item_rels
                  set order_n = :i
                  where rel_id = :rel_id
      </querytext>
</fullquery>

 
<fullquery name="cms::rel::sort_child_item_order.get_child_order">      
      <querytext>
      
            select
              rel_id
            from
              cr_child_rels
            where
              parent_id = :item_id
            order by
              order_n, rel_id
        
      </querytext>
</fullquery>

<fullquery name="cms::rel::sort_child_item_order.reorder">      
      <querytext>
  	        update cr_child_rels
                  set order_n = :i
                  where rel_id = :rel_id
      </querytext>
</fullquery>
 
<fullquery name="cms::rel::valid_cr_item_rel_relation_p.valid_relation_p">      
      <querytext>
	select 1 
          from cr_type_relations tr 
         where tr.content_type = :content_type 
           and tr.target_type = :target_type 
           and (tr.max_n is null
                or (select count(*) from cr_item_rels
                     where item_id = :item_id
                       and relation_tag = tr.relation_tag) < tr.max_n)
          and not exists (select 1 from cr_item_rels ir
                           where related_object_id = :object_id
                             and item_id = :item_id)
      </querytext>
</fullquery>

<fullquery name="cms::rel::valid_cr_item_child_rel_relation_p.valid_relation_p">      
      <querytext>
	select 1 
          from cr_type_children tc
         where tc.parent_type = :parent_type 
           and tc.child_type = :child_type 
           and (tc.max_n is null
                or (select count(*) from cr_child_rels
                     where parent_id = :item_id
                       and relation_tag = tc.relation_tag) < tc.max_n)
          and not exists (select 1 from cr_child_rels cr
                           where child_id = :object_id
                             and parent_id = :item_id)
      </querytext>
</fullquery>

<fullquery name="cms::rel::add_child.add_child">      
      <querytext>
	insert into cr_child_rels (
		rel_id, parent_id, child_id, relation_tag, order_n
	) values (
		:rel_id, :item_id, :object_id, :relation_tag, :order_n
	)
      </querytext>
</fullquery>

<fullquery name="cms::rel::remove_child.remove_child">      
      <querytext>
	delete from cr_child_rels where rel_id = :rel_id
      </querytext>
</fullquery>
 
</queryset>
