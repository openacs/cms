request create -params {
  revision_id -datatype integer
}

db_transaction {
    set doc_id [db_exec_plsql export_revision "
                             begin
                                 :1 := content_revision.export_xml(:revision_id);
                             end;"]

    template::query get_xml_doc xml_doc onevalue "
                select doc from cr_xml_docs where doc_id = :doc_id
                "
}

ns_return 200 text/xml $xml_doc

