# Form for uploading a revision in XML format.

set page_title "Upload Revision"

request create
request set_param item_id -datatype integer -optional
request set_param parent_id -datatype integer -optional
request set_param content_type -datatype keyword -optional

form create upload -html { enctype multipart/form-data } -elements {
  item_id -datatype integer -param -widget hidden -optional
  revision_id -datatype integer -widget hidden
  create_p -datatype keyword -widget hidden -value "f"
  parent_id -datatype integer -param -widget hidden -optional
  content_type -datatype keyword -param -widget hidden -optional
}


# if item_id is null, then we need to create the item
if { [template::util::is_nil item_id] } {

    # parent_id and content_type must not be null!
    if { [template::util::is_nil parent_id] || \
	    [template::util::is_nil content_type] } {
	ns_log Notice "revision-upload.tcl:  BAD CREATE ITEM PARAMETERS"
	template::forward "../sitemap/index"
    }

    template::query get_new_item new_item onerow "
      select 
        NVL(content_item.get_path(:parent_id), '/') as item_path,
        pretty_name as content_type_name
      from
        acs_object_types
      where
        object_type = :content_type
    " 

    if { [template::util::is_nil new_item] } {
	ns_log Notice "revision-upload.tcl - ERROR: BAD PARENT_ID OR CONTENT_TYPE - $parent_id, $content_type"
	template::forward "../sitemap/index"
    }

    set page_title "Create a New $new_item(content_type_name)"

    element create upload item_path \
	-datatype text \
	-widget inform \
	-label "Folder" \
	-value $new_item(item_path)

    element create upload content_type_name \
	-datatype keyword \
	-widget inform \
	-label "Content Type" \
	-value $new_item(content_type_name)

    element create upload name \
	    -datatype keyword \
	    -widget text \
	    -html { maxlength 30 } \
	    -label "File Name"

    element set_properties upload create_p -value "t"
}

element create upload xml_file \
	-datatype text \
	-widget file \
	-label "XML File"

  





if { [form is_request upload] } { 
 
  query revision_id onevalue "select acs_object_id_seq.nextval from dual"
  element set_properties upload revision_id -value $revision_id
}


# Process the form
if { [form is_valid upload] } {

  form get_values upload revision_id create_p

  set db [template::begin_db_transaction]

  # create the new item first, if necessary
  # otherwise read item_id from the form
  if { [string equal $create_p "t"] } {
    
    form get_values upload name parent_id content_type

    ns_log Notice "revision-upload.tcl - Creating content item... $name"
    ns_ora exec_plsql_bind $db "begin 
      :item_id := content_item.new(
          name          => :name, 
          parent_id     => :parent_id, 
          content_type  => :content_type,
          creation_user => [User::getID],
          creation_ip   => '[ns_conn peeraddr]' ); 
      end;" item_id
  } else {
    form get_values upload item_id
  }

  ns_log Notice "XML [ns_queryget xml_file.tmpfile]"
  set tmp_filename [ns_queryget xml_file.tmpfile]
  set doc [template::util::read_file $tmp_filename]

  ns_ora clob_dml $db "insert into cr_xml_docs 
  values ($revision_id, empty_clob()) returning doc into :1" $doc

  ns_ora exec_plsql_bind $db "begin
    :revision_id := content_revision.import_xml(
      :item_id, :revision_id, :revision_id);
  end;" revision_id

  template::end_db_transaction
  template::release_db_handle

  template::forward index?item_id=$item_id
}
