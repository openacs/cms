set page_title "Add Comment"

request create -params {
  item_id -datatype integer 
}

template::query item_title onevalue "
  select content_item.get_title(:item_id) from dual
"

form create add_comment -elements "
  journal_id -datatype integer -widget hidden
  object_id -datatype integer -widget hidden -value $item_id
  item_title -datatype text -widget inform -value $item_title \
      -label {Item Title}
  msg -datatype text -widget textarea -html { rows 10 cols 40 } \
      -label {Message}
"

if { [form is_request add_comment] } {
  template::query journal_id onevalue "
    select acs_object_id_seq.nextval from dual
  "
  element set_properties add_comment journal_id -value $journal_id
}

if { [form is_valid add_comment] } {

  form get_values add_comment journal_id object_id msg

  set user_id [User::getID]
  set ip_address [ns_conn peeraddr]

  set db [template::begin_db_transaction]

  ns_ora exec_plsql_bind $db "begin
    :journal_id := journal_entry.new(
      journal_id => :journal_id,
      object_id => :object_id,
      action => 'comment',
      action_pretty => 'Comment',
      creation_user => :user_id,
      creation_ip  => :ip_address,
      msg => :msg );
    end;" journal_id

  template::end_db_transaction
  template::release_db_handle

  template::forward "index?item_id=$object_id"
}