request create -params {
  folder_id -datatype integer
}

if { ! [request is_valid] } { return }

set submit [ns_queryget submit] 

if { ! [string equal $submit {}] } {

  if { $submit == "Copy" } {

    set db [begin_db_transaction]
    set creation_user [User::getID]
    set creation_ip [ns_conn peeraddr]

    foreach template_id [ns_querygetall template_id] {
      ns_ora dml $db "declare copy_id integer; begin 
        copy_id := content_item.copy2(
          :template_id, :folder_id, :creation_user, :creation_ip
        );
        insert into cr_templates (template_id) values (copy_id);
      end;"
    }

    end_db_transaction
  }

  template::forward [ns_queryget return_url]
}

query path onevalue "select content_item.get_path(:folder_id) from dual"