# download.tcl
#
# see if this person is authorized to read the file in question
# and if so, write it to the connection.

template::request create
template::request set_param revision_id -datatype integer

set user_id [User::getID]

template::query get_iteminfo iteminfo onerow "
  select
    item_id, content_revision.is_live( revision_id ) is_live
  from
    cr_revisions
  where
    revision_id = :revision_id
"

template::util::array_to_vars iteminfo

# item_id, is_live

# check cm permissions on file
if { ![string equal $is_live t] } {
  content::check_access $item_id cm_read -user_id $user_id
}

cr_write_content -revision_id $revision_id
