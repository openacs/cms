request create -params {
  revision_id -datatype integer
}

set db [get_db_handle]

# query for the path and ID of the template

query info onerow "
  select 
    content_item.get_path(item_id) path, item_id 
  from 
    cr_items 
  where item_id = (
    select item_id from cr_revisions where revision_id = :revision_id)"

# write the template to the file system

set text [content::get_content_value $revision_id]

set path [content::get_template_path]/$info(path)

util::write_file $path.adp $text

# update the live revision

set template_id $info(item_id)

ns_ora dml $db "update cr_items set live_revision = :revision_id
                where item_id = :template_id"

release_db_handle

set return_url [ns_set iget [ns_conn headers] Referer]
template::forward $return_url

