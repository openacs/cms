# attributes-edit.tcl
# custom form for content_type = image

request create
request set_param item_id -datatype integer

set db [ns_db gethandle]

# permissions check - need cm_write on item_id to add a revision
content::check_access $item_id cm_write -user_id [User::getID] -db $db

form create image -html { enctype "multipart/form-data" } -elements {
    item_id      -datatype integer -widget hidden -param
    revision_id  -datatype integer -widget hidden
}

query item_info onerow "
  select 
    i.name, i.latest_revision, r.title 
  from 
    cr_items i, cr_revisions r
  where 
    i.item_id = :item_id
  and
    i.item_id = r.item_id
  and
    i.latest_revision = r.revision_id
" -db $db

template::util::array_to_vars item_info

ns_db releasehandle $db


content::add_attribute_elements image image $latest_revision

element set_properties image mime_type -widget hidden
element set_properties image width -help_text "(optional)"
element set_properties image height -help_text "(optional)"

if { [form is_request image] } {
    
    set revision_id [content::get_object_id]
    element set_value image revision_id $revision_id

}


if { [form is_valid image] } {

    form get_values image item_id revision_id title description width height

    # some auditing info
    set user_id [User::getID]
    set ip_address [ns_conn peeraddr]

    set db [ns_db gethandle]
    ns_ora dml $db "begin transaction"

    query latest_revision onevalue "
      select
        latest_revision
      from
        cr_items
      where
        item_id = :item_id
    " -db $db

    set sql "
      begin
      :revision_id := content_revision.copy(
          target_item_id => :item_id,
          copy_id        => :revision_id,
          revision_id    => :latest_revision,
          creation_user  => :user_id,
          creation_ip    => :ip_address 
      );
      end;"

    # create the revision
    if { [catch {ns_ora exec_plsql_bind $db $sql revision_id} errmsg] } {

	# check for dupe submit
	query clicks onevalue "
	  select
	    count(1)
	  from
	    cr_revisions
	  where
	    revision_id = :revision_id
	" -db $db

	ns_ora dml $db "abort transaction"
	ns_db releasehandle $db

	if { $clicks > 0 } {
	    # double click error - forward to view the item
	    template::forward \
		    "../../index?item_id=$item_id"
	    return
	} else {
	    template::request::error new_revision_error \
		    "custom/image/attributes-edit.tcl -
	               while creation new revision for item $item_id - $errmsg"
	    return
	}
    }

    # update the new title and description
    ns_ora dml $db "
      update cr_revisions
        set title = :title,
        description = :description
        where revision_id = :revision_id"


    # update image dimensions
    ns_ora dml $db "
      update images
        set width = :width,
        height = :height
        where image_id = :revision_id"

    ns_ora dml $db "end transaction"
    ns_db releasehandle $db

    template::forward "../../index?item_id=$item_id"
}
