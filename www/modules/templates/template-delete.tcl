# templates/template-delete.tcl
# Delete a template
# throw an error if the template has child items

template::request create
template::request set_param template_id -datatype keyword
template::request set_param parent_id -datatype keyword -optional


# Determine if the item has subitems is empty
template::query get_status empty_p onevalue "
  select 't' from dual 
    where not exists (
      select 
        1 
      from
        cr_templates t, acs_objects o
      where
        o.object_id = t.template_id
      and
        o.context_id = :template_id
      and not exists (select 1 from cr_revisions 
                        where revision_id = t.template_id))
"

# If nonempty, show error
if { [template::util::is_nil empty_p] } {
    set message "This item contains subitems and cannot be deleted"
    set return_url "modules/templates/index"
    set passthrough [list [list id $template_id] [list parent_id $parent_id]]
    template::redirect "../../../error?message=$message&return_url=$return_url&passthrough=$passthrough"
} else {
    # Otherwise, delete the item
    
    db_transaction {
        db_exec_plsql delete_template "
      begin 
        content_template.delete(:template_id); 
      end;" 
    }

    template::forward "../templates/index?id="
}

