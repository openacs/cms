request create -params {
  folder_id -datatype integer
}

if { ! [request is_valid] } { return }

set submit [ns_queryget submit] 

if { ! [string equal $submit {}] } {

  if { $submit == "Move" } {

    db_transaction {
        set creation_user [User::getID]
        set creation_ip [ns_conn peeraddr]

        foreach template_id [ns_querygetall template_id] {
            db_exec_plsql move_item "begin 
        content_item.move(
          :template_id, :folder_id
        );
      end;"
        }
    }
  }

  template::forward [ns_queryget return_url]
}

template::query get_path path onevalue "select content_item.get_path(:folder_id) from dual"

