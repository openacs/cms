# /types/register-mime-types.tcl
# A form for registering mime types to a content type


request create
request set_param content_type -datatype keyword -value 'content_revision'

template::query get_module_id module_id onevalue "
  select module_id from cm_modules where key = 'types'
"

# permissions check - must have cm_examine
content::check_access $module_id cm_examine -user_id [User::getID]

template::query get_name content_type_name onevalue "
  select
    pretty_name
  from
    acs_object_types
  where
    object_type = :content_type
"

template::query get_unreg_mime_types unregistered_mime_types multilist "
  select
    label, mime_type
  from 
    cr_mime_types
  where
    not exists ( select 1
                 from 
                   cr_content_mime_type_map
                 where
                   mime_type = cr_mime_types.mime_type
                 and
                   content_type = :content_type )
  order by
    label
"

set unregistered_mime_types_count [llength $unregistered_mime_types]

if { [template::util::is_nil content_type_name] } {
    ns_log Notice \
      "register-mime-types.tcl - ERROR:  BAD CONTENT_TYPE - $content_type"
    template::forward "index?id=content_revision"
}

template::query get_reg_mime_types registered_mime_types multirow "
  select 
    label, m.mime_type
  from
    cr_mime_types m, cr_content_mime_type_map map
  where
    m.mime_type = map.mime_type
  and
    map.content_type = :content_type
  order by
    label
" 
  
set page_title "Register MIME types to $content_type_name"


form create register 
#-action "mime-types"

element create register id \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create register content_type \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create register mime_type \
	-datatype text \
	-widget select \
	-label "Register MIME Types" \
	-options $unregistered_mime_types



if { [form is_valid register] } {
    form get_values register content_type mime_type

    db_transaction {

        db_exec_plsql register_mime_type "
      begin
        content_type.register_mime_type (
            content_type => :content_type,
            mime_type    => :mime_type
        );
      end;"

    }

    content_method::flush_content_methods_cache $content_type

    template::forward "index?id=$content_type"
}
