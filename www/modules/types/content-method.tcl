request create
request set_param content_type -datatype keyword -value content_revision
request set_param return_url -datatype text -value ""

# permissions check - user must have cm_examine on the types module
set types_module_id [cm::modules::get_module_id types]
content::check_access $types_module_id cm_examine -user_id [User::getID]

# default return_url
if { [template::util::is_nil return_url] } {
    set return_url "index?id=$content_type"
}

set db [template::get_db_handle]

# fetch the content methods registered to this content type
template::query content_methods multirow "
  select
    m.content_method, label, is_default, description
  from
    cm_content_type_method_map map, cm_content_methods m
  where
    m.content_method = map.content_method
  and
    map.content_type = :content_type
  order by
    is_default desc, label
" 


# text_entry content method filter
# don't show text entry if a text mime type is not registered to the item
template::query has_text_mime_type onevalue "
  select
    count( mime_type )
  from
    cr_content_mime_type_map
  where
    mime_type like ('%text/%')
  and
    content_type = :content_type
" 

if { $has_text_mime_type == 0 } {
    set text_entry_filter_sql "and content_method ^= 'text_entry'"
} else {
    set text_entry_filter_sql ""
}


# fetch the content methods not register to this content type
template::query unregistered_content_methods multilist "
  select
    label, m.content_method
  from
    cm_content_methods m
  where
    not exists ( 
      select 1
      from
        cm_content_type_method_map
      where
        content_method = m.content_method
      and
        content_type = :content_type )
  $text_entry_filter_sql
  order by 
    label
" 

set unregistered_method_count [llength $unregistered_content_methods]

template::release_db_handle



# form to register unregistered content methods to this content type
form create register

element create register content_type \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create register return_url \
	-datatype text \
	-widget hidden \
	-value $return_url

element create register content_method \
	-datatype keyword \
	-widget select \
	-options $unregistered_content_methods
	
element create register submit \
	-datatype keyword \
	-widget submit \
	-label "Register"



if { [form is_valid register] } {

    form get_values register content_type content_method
    
    set db [template::begin_db_transaction]


    template::query content_method_add dml "
      begin
      content_method.add_method (
          content_type   => :content_type,
          content_method => :content_method,
          is_default     => 'f'
      );
      end;
    "

    template::end_db_transaction
    template::release_db_handle

    content_method::flush_content_methods_cache $content_type

    template::forward $return_url
}
