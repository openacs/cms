# publish.tcl
# Publish a revision to the file system.

request create
request set_param revision_id -datatype integer

set root_path [ns_info pageroot]

set db [template::begin_db_transaction]

template::query iteminfo onerow "
  select
    item_id,
    content_item.is_publishable( item_id ) as publish_p
  from
    cr_revisions
  where
    revision_id = :revision_id
" 


template::util::array_to_vars iteminfo
# item_id, publish_p


if { [string equal $publish_p t] } {

   # publish::publish_revision $revision_id

   template::query set_live_revision dml "
     begin 
       content_item.set_live_revision( 
         revision_id => :revision_id 
       );
     end;" 

   publish::unpublish_item $item_id
     
} else {

    ns_ora dml $db "abort transaction"
    template::release_db_handle

    set msg "This item is not in a publishable state" 
    set return_url "index?item_id=$item_id"
    set passthrough { { item_id $item_id } }

    content::show_error $msg $return_url $passthrough
}

template::end_db_transaction
template::release_db_handle

template::forward "index?item_id=$item_id"
