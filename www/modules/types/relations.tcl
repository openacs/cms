# relations.tcl
# display registered relation types
# @author Michael Pih

request create
request set_param type -datatype integer -value content_revision

template::query get_module_id module_id onevalue "
  select module_id from cm_modules where key = 'types'
" 

# permission check - must have cm_examine on types module
content::check_access $module_id cm_examine -user_id [User::getID] 


template::query get_rel_types rel_types multirow "
  select
    pretty_name, target_type, relation_tag, min_n, max_n
  from
    cr_type_relations r, acs_object_types o
  where
    o.object_type = r.target_type
  and
    r.content_type = :type
  order by
    pretty_name, relation_tag
" 


template::query get_child_types child_types multirow "
  select
    pretty_name, child_type, relation_tag, min_n, max_n
  from
    cr_type_children c, acs_object_types o
  where
    c.child_type = o.object_type
  and
    c.parent_type = :type
  order by
    pretty_name, relation_tag
" 
