request create -params {
  folder_id -datatype integer
}

if { ! [request is_valid] } { return }

set submit [ns_queryget submit] 

if { ! [string equal $submit {}] } {

  if { $submit == "Move" } {

    set db [begin_db_transaction]
    set creation_user [User::getID]
    set creation_ip [ns_conn peeraddr]

    foreach template_id [ns_querygetall template_id] {
      ns_ora dml $db "begin 
        content_item.move(
          :template_id, :folder_id
        );
      end;"
    }

    end_db_transaction
  }

  template::forward [ns_queryget return_url]
}

query path onevalue "select content_item.get_path(:folder_id) from dual"

