# /cms/www/modules/items/publish-status.tcl
# Indicates whether or not the item is publishable and displays
#   what needs to be done before this item can be published.
request create
request set_param item_id -datatype integer

# permissions check - requires cm_item_workflow
content::check_access $item_id cm_examine -user_id [User::getID] 

# Query for publish status and release schedule, if any

db_string get_info "" -column_array info

# Build a sentence describing the publishing status

set actions [list]

switch $info(publish_status) {

  Production { 
    set message "This item is in production."
  }

  Ready { 
    set message "This item is ready for publishing. "
    if { ! [string equal $info(start_when) Immediate] } {
      append message "It has been scheduled for release
                      on <b>$info(start_when)</b>."
    } else {
      append message "It has not been scheduled for release."
    }
  }

  Live { 
    set message "This item has been published. "
    if { ! [string equal $info(end_when) Indefinite] } {
      append message "It has been scheduled to expire
                      on <b>$info(end_when)</b>."
    } else {
      append message "It has no expiration date."
    }
  }

  Expired { 
    set message "This item is expired."
  }
}

# determine whether the item is publishable or not

db_1row get_publish_info ""

template::util::array_to_vars publish_info

# if the live revision doesn't exist, the item is unpublishable
if { [template::util::is_nil live_revision] } {
    set is_publishable f
}


# determine if there is an unfinished workflow

set unfinished_workflow_exists [db_string unfinished_exists ""]

# determine if child type constraints have been satisfied

set unpublishable_child_types 0

template::query get_child_types child_types multirow "
  select
    child_type, relation_tag, min_n, 
    o.pretty_name as child_type_pretty, 
    o.pretty_plural as child_type_plural, 
    decode(max_n, null, '-', max_n) max_n,
    (
      select
        count(*)
      from
        cr_child_rels
      where
        parent_id = i.item_id
      and
        content_item.get_content_type( child_id ) = c.child_type
      and
        relation_tag = c.relation_tag
    ) child_count
  from
    cr_type_children c, cr_items i, acs_object_types o
  where
    c.parent_type = i.content_type
  and
    c.child_type = o.object_type
  and
    -- this item is the parent
    i.item_id = :item_id
" -eval {

    # set is_fulfilled to t if the relationship constraints are fulfilled
    #   otherwise set is_fulfilled to f

    # keep track of numbers
    #  difference - the (absolute) number of child items in excess or lack
    #  direction  - whether "more" or "less" child items are needed

    set row(is_fulfilled) t
    set row(difference) 0
    set row(direction) ""

    if { $row(child_count) < $row(min_n) } {
	set row(is_fulfilled) f
	incr unpublishable_child_types
	set row(difference) [expr $row(min_n)-$row(child_count)]
	set row(direction) more
    }
    if { ![string equal $row(max_n) -] && $row(child_count) > $row(max_n) } {
	set row(is_fulfilled) f
	incr unpublishable_child_types
	set row(difference) [expr $row(child_count)-$row(max_n)]
	set row(direction) less
    }
}



# determine if relation type constraints have been satisfied

set unpublishable_rel_types 0

template::query get_rel_types rel_types multirow "
  select
    target_type, relation_tag, min_n, 
    o.pretty_name as target_type_pretty,
    o.pretty_plural as target_type_plural,
    decode(max_n, null, '-', max_n) max_n,
    (
      select
        count(*)
      from
        cr_item_rels
      where
        item_id = i.item_id
      and
        content_item.get_content_type( related_object_id ) = r.target_type
      and
        relation_tag = r.relation_tag
    ) rel_count
  from
    cr_type_relations r, cr_items i, acs_object_types o
  where
    o.object_type = r.target_type
  and
    r.content_type = i.content_type
  and
    i.item_id = :item_id
" -eval {

    # set is_fulfilled to t if the relationship constraints are fulfilled
    #   otherwise set is_fulfilled to f

    # keep track of numbers
    #  difference - the (absolute) number of related items in excess or lack
    #  direction  - whether "more" or "less" related items are needed

    set row(is_fulfilled) t
    set row(difference) 0
    set row(direction) ""

    if { $row(rel_count) < $row(min_n) } {
	set row(is_fulfilled) f
	incr unpublishable_rel_types
	set row(difference) [expr $row(min_n)-$row(rel_count)]
	set row(direction) more
    }
    if { ![string equal $row(max_n) -] && $row(rel_count) > $row(max_n) } {
	set row(is_fulfilled) f
	incr unpublishable_rel_types
	set row(difference) [expr $row(rel_count)-$row(max_n)]
	set row(direction) less
    }

}


