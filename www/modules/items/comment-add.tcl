set page_title "Add Comment"

request create -params {
  item_id -datatype integer 
}

set item_title [db_string get_title ""]

form create add_comment -elements "
  journal_id -datatype integer -widget hidden
  object_id -datatype integer -widget hidden -value $item_id
  item_title -datatype text -widget inform -value $item_title \
      -label {Item Title}
  msg -datatype text -widget textarea -html { rows 10 cols 40 } \
      -label {Message}
"

if { [form is_request add_comment] } {
    set journal_id [db_string get_journal_id ""]
    element set_properties add_comment journal_id -value $journal_id
}

if { [form is_valid add_comment] } {

  form get_values add_comment journal_id object_id msg

  set user_id [User::getID]
  set ip_address [ns_conn peeraddr]

  db_transaction {
      set journal_id [db_exec_plsql new_entry "
    begin
      :1 = journal_entry.new(
                             journal_id => :journal_id,
                             object_id => :object_id,
                             action => 'comment',
                             action_pretty => 'Comment',
                             creation_user => :user_id,
                             creation_ip  => :ip_address,
                             msg => :msg );
    end;"]

  }

  template::forward "index?item_id=$object_id"
}
