# attributes-edit.tcl
# custom form for content_type = image

request create
request set_param item_id -datatype integer

# permissions check - need cm_write on item_id to add a revision
content::check_access $item_id cm_write -user_id [User::getID] -db $db

form create image -html { enctype "multipart/form-data" } -elements {
    item_id      -datatype integer -widget hidden -param
    revision_id  -datatype integer -widget hidden
}

template::query get_item_info item_info onerow "
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
"

template::util::array_to_vars item_info


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

    db_transaction {
        template::query get_latest latest_revision onevalue "
      select
        latest_revision
      from
        cr_items
      where
        item_id = :item_id
    " 

        # create the revision
        if { [catch {db_exec_plsql "
      begin
      :1 := content_revision.copy(
          target_item_id => :item_id,
          copy_id        => :revision_id,
          revision_id    => :latest_revision,
          creation_user  => :user_id,
          creation_ip    => :ip_address 
      );
      end;"  } revision_id] } {

            # check for dupe submit
            template::query get_clicks clicks onevalue "
	  select
	    count(1)
	  from
	    cr_revisions
	  where
	    revision_id = :revision_id
	" 

            db_dml abort "abort transaction"

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
        db_dml update_revisions "
      update cr_revisions
        set title = :title,
        description = :description
        where revision_id = :revision_id"


        # update image dimensions
        db_dml update_images "
      update images
        set width = :width,
        height = :height
        where image_id = :revision_id"
    }

    template::forward "../../index?item_id=$item_id"
}
