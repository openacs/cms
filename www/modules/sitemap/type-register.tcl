# register content types from clipboard to a folder

request create
request set_param folder_id -datatype integer


set clip [clipboard::parse_cookie]
set marked_types [clipboard::get_items $clip "types"]
    
set sql "begin
           content_folder.register_content_type(
               folder_id        => :folder_id,
               content_type     => :type,
               include_subtypes => 'f'
           );
         end;"

set db [template::begin_db_transaction]
foreach type $marked_types {

    ns_ora dml $db $sql
}
template::end_db_transaction
template::release_db_handle

cms_folder::flush_registered_types $folder_id

clipboard::free $clip

forward "attributes?folder_id=$folder_id"
