request create -params {
  revision_id -datatype integer
}

set db [template::get_db_transaction]

ns_ora exec_plsql_bind $db "begin
  :doc_id := content_revision.export_xml(:revision_id);
end;" doc_id

template::query xml_doc onevalue "
  select doc from cr_xml_docs where doc_id = :doc_id
"

template::end_db_transaction
template::release_db_handle

ns_return 200 text/xml $xml_doc

