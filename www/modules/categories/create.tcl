request create -params {
  parent_id -datatype integer -optional
  mount_point -datatype keyword -optional -value categories
}

form create add_keyword

element create add_keyword keyword_id \
  -label "Keyword ID" -datatype integer -widget hidden -optional

element create add_keyword parent_id \
  -label "Parent ID" -datatype integer -widget hidden -optional -param

element create add_keyword heading \
  -label "Heading" -datatype text -widget text -html { size 30 }

element create add_keyword description -optional \
  -label "Description" -datatype text -widget textarea -html { rows 5 cols 60 }

if { [form is_request add_keyword] } {
  template::query keyword_id onevalue "
    select acs_object_id_seq.nextval from dual
  "
  element set_properties add_keyword keyword_id -value $keyword_id
}

if { [form is_valid add_keyword] } {

  form get_values add_keyword keyword_id heading parent_id description
  set user_id [User::getID]
  set ip [ns_conn peeraddr]

  set db [template::begin_db_transaction]

  set sql "
    begin :1 := content_keyword.new(
      heading => :heading, 
      description => :description, 
      keyword_id => :keyword_id,
      creation_user => :user_id,
      creation_ip => :ip"

  if { ![template::util::is_nil parent_id] } {
    append sql ",
      parent_id => :parent_id"
  }

  append sql "); end;"

  ns_ora exec_plsql_bind $db $sql [list 1] keyword_id
  template::end_db_transaction
  template::release_db_handle

  template::forward "refresh-tree?id=_all_&goto_id=$parent_id&mount_point=$mount_point"
}


  

