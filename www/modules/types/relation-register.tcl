request create
request set_param rel_type     -datatype keyword
request set_param content_type -datatype keyword -value content_revision

set db [template::get_db_handle]

template::query module_id onevalue "
  select module_id from cm_modules where key = 'types'
" 

# permissions check - must have cm_write on the types module
content::check_access $module_id cm_write -user_id [User::getID]

form create relation -elements {
    rel_type     -datatype keyword -widget hidden -param
    content_type -datatype keyword -widget hidden -param
}

if { [string equal $rel_type item_rel] } {
    set rel_type_pretty "Item"
    set type_label "Related Object Type"

} elseif { [string equal $rel_type child_rel] } {
    set rel_type_pretty "Child"
    set type_label "Child Content Type"

} else {
    template::release_db_handle
    template::forward index?id=$content_type
}

template::query pretty_name onevalue "
  select
    pretty_name
  from
    acs_object_types
  where
    object_type = :content_type
" 

template::query target_types multilist "
  select
    lpad(' ', level, '-') || pretty_name, object_type
  from
    acs_object_types
  connect by
    prior object_type = supertype
  start with
    object_type = 'content_revision'
" 

template::release_db_handle


element create relation target_type \
	-datatype keyword \
	-widget select \
	-options $target_types \
	-label $type_label

element create relation relation_tag \
	-datatype text \
	-html { size 30 } \
	-label "Relation Tag"

element create relation min_n \
	-datatype integer \
	-html { size 4 } \
	-label "Min Relations"

element create relation max_n \
	-datatype integer \
	-html { size 4 } \
	-label "Max Relations (optional)" \
	-optional








if { [form is_valid relation] } {
    form get_values relation \
	    rel_type content_type target_type relation_tag min_n max_n

    # max_n should be null
    if { [template::util::is_nil max_n] } {
	set max_n ""
    }

    if { [string equal $rel_type item_rel] } {
	set sql "
	  begin
          content_type.register_relation_type (
	      content_type => :content_type,
	      target_type  => :target_type,
	      relation_tag => :relation_tag,
              min_n        => :min_n,
              max_n        => :max_n
          );
          end;"

    } elseif { [string equal $rel_type child_rel] } {
	set sql "
	  begin
	  content_type.register_child_type (
	      parent_type  => :content_type,
	      child_type   => :target_type,
              relation_tag => :relation_tag,
	      min_n        => :min_n,
	      max_n        => :max_n
          );
          end;"
    }

    set db [template::begin_db_transaction]

    if { [catch {template::query register_rel_types dml $sql} errmsg] } {
	template::release_db_handle
	template::request::error register_relation_type \
		"Could not register relation type - $errmsg"
    }
    
    template::end_db_transaction
    template::release_db_handle

    template::forward "index?id=$content_type"
}