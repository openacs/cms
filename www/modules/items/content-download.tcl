# download.tcl
#
# see if this person is authorized to read the file in question
# guess the MIME type from the original client filename
# have the Oracle driver grab the BLOB and write it to the connection


template::request create
template::request set_param revision_id -datatype integer

set user_id [User::getID]

set db [template::get_db_handle]

template::query iteminfo onerow "
  select
    item_id, mime_type, content_revision.is_live( revision_id ) is_live
  from
    cr_revisions
  where
    revision_id = :revision_id
"

template::util::array_to_vars iteminfo
# item_id, mime_type, is_live

# check cm permissions on file
if { ![string equal $is_live t] } {
  content::check_access $item_id cm_read -user_id $user_id
}

template::query file_name onevalue "
  select
    name
  from
    cr_items
  where
    item_id = ( select
                  item_id
                from
                  cr_revisions
                where
                  revision_id = :revision_id )
"

template::release_db_handle


set headers_so_far "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $mime_type\n"

set set_headers_i 0
set set_headers_limit [ns_set size [ns_conn outputheaders]]
while {$set_headers_i < $set_headers_limit} {
    append headers_so_far \
	    "[ns_set key [ns_conn outputheaders] $set_headers_i]: [ns_set value [ns_conn outputheaders] $set_headers_i]\n"
    incr set_headers_i
}
append entire_string_to_write $headers_so_far "\n"
ns_write $entire_string_to_write

set db [template::get_db_handle]

ns_ora write_blob $db "
  select
    content 
  from 
    cr_revisions
  where
    revision_id = $revision_id
"

template::release_db_handle


