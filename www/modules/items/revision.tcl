# View a particular revision of the item.

request create -params {
  revision_id -datatype integer
  mount_point -datatype keyword -value sitemap
}

# flag indicating this is the live revision
set live_revision_p 0


template::query get_revision one_revision onerow "
  select 
    revision_id, title, description, item_id, mime_type, 
    content_revision.get_number( revision_id ) revision_number,
    (
     select 
       label 
     from 
       cr_mime_types 
     where 
       mime_type = cr_revisions.mime_type
    ) mime_type_pretty,
    to_char(publish_date,'Month DD, YYYY') as publish_date_pretty,
    content_length as content_size
  from 
    cr_revisions
  where 
    revision_id = :revision_id
"

template::util::array_to_vars one_revision


# Check permissions - must have cm_examine on the item
content::check_access $item_id cm_examine \
	-mount_point $mount_point \
	-return_url "modules/sitemap/index" 


ns_log notice "user_permissions = [array get user_permissions]"
# validate revision
if { [template::util::is_nil item_id] } {
    template::request::error invalid_revision \
      "revision - Invalid revision - $revision_id"
    return
}


# check if the item is publishable (but does not need live revision)
template::query get_status is_publishable onevalue "
  select content_item.is_publishable( :item_id ) from dual
"


# get total number of revision for this item
template::query get_count revision_count onevalue "
  select count(*) from cr_revisions where item_id = :item_id
"

set valid_revision_p "t"

# flag indicating whether the MIME type of the content is text
set is_text_mime_type f
set is_image_mime_type f
if { [regexp {text/} $mime_type] } {
    set is_text_mime_type t
    template::query get_content content onevalue "
      select 
        blob_to_string(content)
      from
        cr_revisions
      where
        revision_id = :revision_id
    " 
  
    ns_log notice $content

    # HACK: special chars in the text confuse TCL
    if { [regexp {<|>|\[|\]|\{|\}|\$} $content match] } {
      set is_text_mime_type f
    }

} elseif { [regexp {image/} $mime_type] } {
    set is_image_mime_type t
}


# get item info
template::query get_one_item one_content_item onerow "
  select 
    name, locale, live_revision as live_revision_id,
    (
      select 
        pretty_name
      from 
        acs_object_types
      where 
        object_type = cr_items.content_type
    ) content_type,
    content_item.get_path(item_id) as path
  from 
    cr_items
  where 
    item_id = :item_id
" 

template::util::array_to_vars one_content_item
    
if { $live_revision_id == $revision_id } {
  set live_revision_p 1
}

################################################################
################################################################


# get the attribute types for a given revision item
# if attr.table_name is null, then use o.table_name
# if column_name is null, then use the attribute_name
# if id_column is null, then use 'attribute_id' and 'acs_attribute_values'

template::query get_meta_attrs meta_attributes multilist "
  select 
    attribute_id, pretty_name, 
    (select pretty_name from acs_object_types
     where object_type = attr.object_type) object_type,
    nvl(column_name,attribute_name) attribute_name,  
    nvl(attr.table_name,o.table_name) table_name,
    nvl(o.id_column,'object_id') id_column
  from
    acs_attributes attr, 
    (select 
       object_type, table_name, id_column 
     from
       acs_object_types
     where 
       object_type not in ('acs_object','content_revision')
     connect by
       prior supertype = object_type
     start with
       object_type = (select 
                        object_type 
                      from 
                        acs_objects
                      where
                        object_id = :revision_id) ) o
  where
    o.object_type = attr.object_type
  order by
    attr.object_type, attr.sort_order
" 

set attr_columns [list]
set attr_tables [list]
set column_id_cons [list]
set attr_display [list]

foreach meta $meta_attributes {
    set attribute_id   [lindex $meta 0]
    set pretty_name    [lindex $meta 1]
    set object_type    [lindex $meta 2]
    set attribute_name [lindex $meta 3]
    set table_name     [lindex $meta 4]
    set id_column      [lindex $meta 5]

    lappend attr_display [list $pretty_name $object_type]

    # add the column constraint and table to the query only if it
    #   isn't there already
    if { [lsearch -exact $attr_tables $table_name] == -1 } {
	lappend attr_tables $table_name
	lappend column_id_cons "$table_name.$id_column = :revision_id"
    }

    # the attribute value columns we want to fetch are either in
    #   acs_attribute_values (object_id,attribute_id) 
    #   or in $table_name ($id_column)
    if { ![string equal $attribute_name ""] && \
	    ![string equal $table_name ""] } {
	lappend attr_columns "$table_name.$attribute_name"
    } else {
	lappend attr_columns "acs_attribute_values.attr_value"

	if { [lsearch -exact $attr_tables "acs_attribute_values"] == -1 } {
	    lappend attr_tables "acs_attribute_values"
	    lappend column_id_cons \
		    "acs_attribute_values.attribute_id = $attribute_id
                     and acs_attribute_values.object_id = :revision_id"
	}
    }
}

if { ![string equal $attr_columns ""] } {

    template::query get_attr_values attribute_values multilist "
      select 
        [join $attr_columns ", "]
      from
        [join $attr_tables ", "]
      where
        [join $column_id_cons " and "]"


    # write the body of the attribute display table to $revision_attr_html
    set revision_attr_html ""
    set i 0
    set attribute_count [llength $attribute_values]
    foreach attr_value [lindex $attribute_values 0] {
	set pretty_name [lindex [lindex $attr_display $i] 0]
	set object_type [lindex [lindex $attr_display $i] 1]
	
	if { [expr [expr $i+1] % 2] == 0 } {
	    set bgcolor "#EEEEEE"
	} else {
	    set bgcolor "#ffffff"
	}
	if { [string equal $attr_value ""] } {
	    set attr_value "&nbsp"
	}

	append revision_attr_html "
        <tr bgcolor=\"$bgcolor\">
          <td>$pretty_name</td>
          <td>$object_type</td>
          <td>$attr_value</td>
        </tr>
        "
	incr i
      }
} else {
  set revision_attr_html ""
}

set page_title \
	"$title : Revision $revision_number of $revision_count for $name"

