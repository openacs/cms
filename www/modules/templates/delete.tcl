request create -params {
  folder_id -datatype integer
}

if { ! [request is_valid] } { return }

# check for a submission

set submit [ns_queryget submit] 

if { ! [string equal $submit {}] } {

  if { $submit == "Delete" } {

    set db [begin_db_transaction]

    foreach template_id [ns_querygetall template_id] {
      ns_ora dml $db "begin content_template.delete(:template_id); end;"
    }

    end_db_transaction
  }

  template::forward [ns_queryget return_url]
}

