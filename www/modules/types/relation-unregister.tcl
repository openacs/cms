# relation-unregister.tcl
# Unregister a relation type from a content type
# @author Michael Pih

request create
request set_param rel_type -datatype keyword -value item
request set_param content_type -datatype keyword
request set_param target_type -datatype keyword
request set_param relation_tag -datatype text -value ""

set db [template::get_db_handle]

template::query module_id onevalue "
  select module_id from cm_modules where key = 'types'
"

# permissions check - must have cm_write on the types module
content::check_access $module_id cm_write -user_id [User::getID]

if { [string equal $rel_type child_rel] } {

    set sql "
      begin
      content_type.unregister_child_type(
          parent_type  => :content_type,
          child_type   => :target_type,
          relation_tag => :relation_tag
      );
      end;"

} elseif { [string equal $rel_type item_rel] } {

    set sql "
      begin
      content_type.unregister_relation_type(
          content_type  => :content_type,
          target_type   => :target_type,
          relation_tag  => :relation_tag
      );
      end;"

} else {
    # bad rel_type, don't do anything
    template::release_db_handle
    template::forward "index?id=$content_type"
}


if { [catch {ns_ora dml $db $sql} errmsg] } {
    template::release_db_handle
    template::request::error unregister_relation_type \
	    "Could not unregister relation type - $errmsg"
}

template::release_db_handle

template::forward "index?id=$content_type"