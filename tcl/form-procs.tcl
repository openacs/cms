namespace eval content {
  # namespace import seems to prevent content:: procs from being recognized
  # namespace import ::template::query ::template::form ::template::element
}

# Helper proc: query out all the information neccessary to create
# a custom form element based on stored metadata
# Requires the variable content_type to be set in the calling frame

# RBM: FIX ME! See comment on line 197
ad_proc content::query_form_metadata { 
  {datasource_name rows} {datasource_type multirow} \
  {extra_where {}} {extra_orderby {}}
} {

  # query for all attribute widget param values associated with a content 
  #   the 3 nvl subqueries are necessary because we cannot outer join
  #   to more than one table without doing multiple subqueries (which is
  #   even less efficient than this way)

  upvar __query query
  set query [db_map attributes_query_1] 
 
  if { ![template::util::is_nil extra_where] } {      
    append query "\n   and\n      $extra_where"
  }

  append query "
    order by
      attributes.tree_level, attributes.sort_order desc, 
      attributes.attribute_id, params.param_id"
  
  if { ![template::util::is_nil extra_orderby] } {
    append query ", $extra_orderby"
  }  

  uplevel "
    template::query get_form_metadata $datasource_name $datasource_type \{$__query\}
  "

}

# Process the query and assemble the "element create..." statement
# PRE:  uber-query has been run
# POST: html_params, code_params set; returns the index of the next
# available row
ad_proc content::assemble_form_element { datasource_ref the_attribute_name start_row {db {}}} {

  upvar "${datasource_ref}:rowcount" rowcount
  upvar code_params code_params
  upvar content_type content_type
  upvar opts opts

  set code_params   [list]
  set html_params   [list]

  # Process the results of the query. 
  for { set i $start_row } { $i <= $rowcount  } { incr i } {
    upvar "${datasource_ref}:${i}" q_row

    if { ![string equal $q_row(attribute_name) $the_attribute_name] } {
      break
    }

    template::util::array_to_vars q_row

    content::get_revision_create_element
  }
  set last_row $i

  # All the neccessary variables should still be set
  get_element_default_params

  # eval the last "element create" string
  if { [llength $html_params] } {
    # widget has html parameters
    lappend code_params -html $html_params
  }

  # Append any other parameters directly to the element create statement
  foreach name {content_type revision_id item_id} {
    if { [info exists opts($name)] } {
      unset opts($name)
    }
  }
  foreach name [array names opts] {
    lappend code_params "-${name}" $opts($name)
  }

  return $last_row
}

# Create a form widget based on the given attribute. Query parameters
# out of the database, override them with the passed-in parameters
# if they exist.
# If the -revision_id flag exists, fills in the value of the attribute from 
# the database, based on the given revision_id.
# If the -content_type flag exists, uses the attribute for the given content
# type (without inheritance). 
# If the -item_id flag is present, the live revision for the item will be 
# used.
# If the -item_id and the -revision_id flags are missing, the -content_type
# flag must be specified.
# Example: 
# content::create_form_element my_form width -revision_id $image_id -size 10
#   This call will create an element representing the width attribute
#   of the image type, with the textbox size set to 10 characters,
#   and query the current value of the attribute out of the database.

ad_proc content::create_form_element {
    form_name attribute_name args
} {
  template::util::get_opts $args

  # Get the revision id if the item id is specified, or if
  # it is passed in directly
  if { ![template::util::is_nil opts(revision_id)] } {
    set revision_id $opts(revision_id)
      
  } elseif { ![template::util::is_nil opts(item_id)] } {
      
    set item_id $opts(item_id)
    template::query get_revision_id revision_id onevalue "
      select content_item.get_latest_revision(:item_id) from dual
    "
  }

  if { [info exists opts(content_type)] } {
    # The type is known: use it
    set content_type $opts(content_type)
  } else {
 
    # Figure out the type based on revision_id
    if { ![info exists revision_id] } {
      template::request error invalid_element_flags "
         No revision_id, item_id or content_type specified in 
         content::create_form_element for attribute ${form_name}:${attribute_name}"
      return
    }
   
    template::query get_content_type content_type onevalue "
       select content_type from cr_items i, cr_revisions r
       where r.item_id = i.item_id
       and   r.revision_id = :revision_id"
  }

  # Run the gigantic uber-query. This is somewhat wasteful; should
  # be replaced by 2 smaller queries: one for the attribute_id, one
  # for parameter types and values.
  query_form_metadata params multirow "attribute_name = :attribute_name"
  
  if { ${params:rowcount} < 1} {
    error "No widgets are registered for ${content_type}.${attribute_name}"
  }

  template::util::array_to_vars "params:1"
  assemble_form_element params $attribute_name 1

  # If the -revision_id switch exists, look up the existing value for the
  # element
  if { ![template::util::is_nil revision_id] && [lsearch $code_params "-value"] < 0 } {
 
    # Handle custom datatypes... Basically, this is done so that
    # the date widget will work :-/
    # In the future, upgrade the date widget and use acs_object.get_attribute

    switch $datatype {
      date {
	  set what [db_map cfe_attribute_name_to_char]
      }

      default {
	  set what [db_map cfe_attribute_name]
      }
    }
    
    template::query get_element_value element_value onevalue "
      select $what from ${table_name}x where revision_id = :revision_id
    "

    lappend code_params -value $element_value -values [list $element_value]
  }

  set form_element "template::element create $form_name $attribute_name $code_params"
  if { ![string equal $is_required t] } {
      append form_element " -optional"
  }

  eval $form_element
}  
  
# generate a form based on metadata

ad_proc content::get_revision_form { 
  content_type item_id form_name {show_sections t} {element_override {}}
} {

    # Convert overrides to an array
    array set overrides $element_override

    set last_type ""
    set last_attribute_name ""
    set new_section_p 1

    set code_params [list]
    set html_params [list]
    
    # Perform a gigantic query to retreive all metadata
    query_form_metadata $db

    # Process the results and create the elements
    for { set i 1 } { $i <= ${rows:rowcount} } { incr i } {
        upvar 0 "rows:${i}" row 
        template::util::array_to_vars row

        # make a new section in the form for each type in the content type hierarchy
        if { $new_section_p == 1 && [string equal $show_sections t]} {
            # put attributes for each supertype in their own section
	    template::form section $form_name $last_type
        }

        # check if attributes should be placed in a new content type section
        if { ! [string equal $type_label $last_type] } {
            set new_section_p 1
        } else {
            set new_section_p 0
        }


        # if the attribute is new
        if { ![string equal $last_attribute_name $attribute_name] } {

            # if this is a new attribute and it isn't the first attribute ( $i != 1 ), 
            #   then evaluate the current "element create" string, and reset the params lists
            if { $i != 1 } {

                if { [llength $html_params] } {
                    # widget has html parameters
                    lappend code_params -html $html_params
                }
                set form_element \
                        "template::element create $form_name $last_attribute_name $code_params"
                #ns_log notice "*** CREATING..."
		#ns_log notice "***   ATTRIBUTE     : $last_attribute_name"
		#ns_log notice "***   TYPE_LABEL    : $last_type"
                eval $form_element
                
                set code_params [list]
                set html_params [list]
            }


            # start a new "element create" string
            get_element_default_params
        }

        # evaluate the param
        get_revision_create_element
        if { [info exists overrides($last_attribute_name)] } {
          set code_params [concat $code_params $overrides($last_attribute_name)]
	}

        set last_attribute_name $attribute_name
	set last_type $type_label
    }
    

    # eval the last "element create" string
    if { [llength $html_params] } {
        # widget has html parameters
        lappend code_params -html $html_params
    }

    set form_element "template::element create $form_name $last_attribute_name $code_params"
    #ns_log notice "***ELEMENT CREATE: $form_element"
    eval $form_element


    # add some default form elements
    eval template::element create $form_name content_type \
            -widget hidden -datatype keyword -value $content_type

    if { ![string equal $item_id ""] } {
        eval template::element create $form_name item_id \
                -widget hidden -datatype integer -value $item_id
    }
}


# PRE: requires datatype, widget, attribute_label, is_required code_params
#      to be set in the calling frame
#
# POST: appends the list of params neccessary to create a new element to code_params
ad_proc content::get_element_default_params {} {

  uplevel {
    lappend code_params -datatype $datatype -widget $widget \
                        -label $attribute_label 
    if { [string equal $is_required "f"] } {
      lappend code_params -optional
    }
  }
}

# PRE:  requires the following variables to be set in the uplevel scope:
#     db, code_params, html_params, 
#     attribute_id, attribute_name, datatype, is_html,
#     param_source, param_type, value
# POST: adds params to the 'element create' command
ad_proc content::get_revision_create_element {} {
    upvar __sql sql
    set sql [db_map get_enum_1]
    
    uplevel {
        if { ![string equal $attribute_name {}] } {
            
            if { [string equal $is_html "t"] } {
                lappend html_params $param $value
            } else {
                
                # if datatype is enumeration, then query acs_enum_values table to
                # build the option list
                if { [string equal $datatype "enumeration"] } {

                    template::query get_enum_values options multilist $__sql
                    lappend code_params -options $options
                }
                
                # if param_source is not 'literal' then 
                # eval or query for the parameter value(s)

                if { ![string equal $param_source ""] } {
                    if { [string equal $param_source "eval"] } {
                        set source [eval $value]
                    } elseif { [string equal $param_source "query"] } {
                        template::query revision_create_get_value source $param_type $value
                    } else {
                        set source $value
                    }
                    lappend code_params "-$param" $source
                }
            }
        }
    }
}


# perform the appropriate DML based on metadata

ad_proc content::process_revision_form { form_name content_type item_id {db{}} } {

    template::form get_values $form_name title description mime_type

    # create the basic revision
    db_exec_plsql new_content_revision {
             begin
	     :revision_id := content_revision.new(
                 title         => :title,
                 description   => :description,
                 mime_type     => :mime_type,
                 text          => ' ',
                 item_id       => content_symlink.resolve(:item_id),
                 creation_ip   => '[ns_conn peeraddr]',
                 creation_user => [User::getID]
             );
             end;
    }

    #ns_ora exec_plsql_bind $db $sql revision_id

    # query for extended attribute tables

    set last_table ""
    set last_id_column ""
    template::query get_extended_attributes rows multirow "
          select 
            types.table_name, types.id_column, attr.attribute_name,
            attr.datatype
          from 
            acs_attributes attr,
            ( select 
                object_type, table_name, id_column, level as inherit_level
              from 
                acs_object_types
              where 
                object_type <> 'acs_object'
              and
                object_type <> 'content_revision'
              connect by 
                prior supertype = object_type
              start with 
                object_type = :content_type) types        
          where 
            attr.object_type (+) = types.object_type
          order by 
            types.inherit_level desc"

    for { set i 1 } { $i <= ${rows:rowcount} } { incr i } {
        upvar 0 "rows:${i}" row
        template::util::array_to_vars row

        #ns_log notice "=========> $attribute_name"
        #ns_log notice "=========> $table_name"
        
        if { ![string equal $last_table $table_name] } {
            if { $i != 1 } {                
                content::process_revision_form_dml
            }
            set columns [list]
            set values [list]
        }
        
        # fetch the value of the attribute from the form
        if { ![template::util::is_nil attribute_name] } {
            set $attribute_name [template::element::get_value \
              $form_name $attribute_name]

            lappend columns $attribute_name

            # If the attribute is a date, get the date
            if { [string equal $datatype date] } {
            set $attribute_name \
              [template::util::date::get_property sql_date [set $attribute_name]]
              # Can't use bind vars because this will be a to_date call
              lappend values "[set $attribute_name]"
            } else {
              lappend values ":$attribute_name"
            }
        }
        set last_table $table_name
        set last_id_column $id_column
    }

    content::process_revision_form_dml

    return $revision_id
}

# helper function for process_revision_form
# PRE: the following variables must be set in the uplevel scope:
#      columns, values, last_table
ad_proc content::process_revision_form_dml {} {

    upvar last_table __last_table
    upvar columns __columns
    upvar values __values
    upvar __sql sql
    set sql [db_map insert_revision_form]
    
    uplevel {

        if { ! [string equal $last_table {}] } {
            lappend columns $last_id_column
            lappend values ":revision_id"

            db_dml insert_revision_form $__sql
        }
    }
}


# Perform an insert for some form, adding all attributes of a 
# specific type
# exclusion_list is a list of all object types for which the elements
#   are NOT to be inserted
# id_value is the revision_id

ad_proc content::insert_element_data { 
  form_name content_type exclusion_list id_value \
  {suffix ""} {extra_where ""}
} {

    set sql_exclusion [template::util::tcl_to_sql_list $exclusion_list]
    set id_value_ref id_value

    set query [db_map ied_get_objects_tree]
  
    if { ![template::util::is_nil extra_where] } {
	append query [db_map ied_get_objects_tree_extra_where]
    }

    append query [db_map ied_get_objects_tree_order_by]

    #ns_log notice "$query"

    set last_table ""
    set last_id_column ""
    template::query insert_element_data rows multirow $query

    for { set i 1 } { $i <= ${rows:rowcount} } { incr i } {
        upvar 0 "rows:${i}" row
        template::util::array_to_vars row

        # ns_log notice "=========> $attribute_name"
        # ns_log notice "=========> $table_name"
        
        if { ![string equal $last_table $table_name] } {
            if { $i != 1 } {                
                content::process_insert_statement
            }
            set columns [list]
            set values [list]
        }
        
        # fetch the value of the attribute from the form
        if { ![template::util::is_nil attribute_name] } {

            set $attribute_name [template::element::get_value \
              $form_name "${attribute_name}${suffix}"]

            lappend columns $attribute_name

            # If the attribute is a date, get the date
            if { [string equal $datatype date] } {
            set $attribute_name \
              [template::util::date::get_property sql_date [set $attribute_name]]
              # Can't use bind vars because this will be a to_date call
              lappend values "[set $attribute_name]"
            } else {
              lappend values ":$attribute_name"
            }
        }
        set last_table $table_name
        set last_id_column $id_column
    }

    content::process_insert_statement

}

# helper function for process_revision_form
# PRE: the following variables must be set in the uplevel scope:
#      columns, values, last_table, id_value_ref
ad_proc content::process_insert_statement {} {
    upvar last_table __last_table
    upvar columns __columns
    upvar values __values
    upvar __sql sql
    set sql [db_map process_insert_statement]
    
    uplevel {

        if { ! [string equal $last_table {}] } {
            lappend columns $last_id_column
            lappend values ":$id_value_ref"

	    db_dml process_insert_statement $__sql
        }
    }
}


# Assemble a passthrough list out of variables
ad_proc content::assemble_passthrough { args } {
  set result [list]
  foreach varname $args {
    upvar $varname var
    lappend result [list $varname $var]
  }
  return $result
}

# Convert passthrough to a URL fragment
ad_proc content::url_passthrough { passthrough } {

  set extra_url ""
  foreach pair $passthrough {
    append extra_url "&[lindex $pair 0]=[lindex $pair 1]"
  }    
  return $extra_url
}

# Assemble a URL out of component parts
ad_proc content::assemble_url { base_url args } {
  set result $base_url
  if { [string first $base_url "?"] == -1 } {
    set joiner "?"
  } else {
    set joiner "&"
  }
  foreach fragment $args {
    set fragment [string trimleft $fragment "&?"]
    if { ![string equal $fragment {}] } {
      append result $joiner $fragment
      set joiner "&"
    }
  }
  return $result
}  

#################################################################

# @namespace content

# Procedures for generating and processing content content creation
# and editing forms..

# @public new_item
# Create a new item, including the initial revision, based on a valid
# form submission.

# @param form_name Name of the form from which to obtain item
# attributes, as well as attributes of the initial revision.  The form
# should include an item_id, name and revision_id.

# @param tmpfile Name of the temporary file containing the content to
# upload for the initial revision.

# @see add_revision

ad_proc content::new_item { form_name { tmpfile "" } } {

  # RBM: Set defaults for PostgreSQL
  # I'm assumming 'name' will always have something
    
  set paramList [list name parent_id item_id locale creation_date creation_user \
		     context_id creation_ip item_subtype content_type title \
		     description mime_type nls_language data]

  set defaultList [list {} null null null "now()" "[User::getID]" \
		       null "[ns_conn peeraddr]" content_item content_revision null \
		       null "text/plain" null null]

  for {set i 0} {$i < [llength $paramList]} {incr i} {
      set defArray([lindex $paramList $i]) [lindex $defaultList $i]
  }
		    
  foreach param $paramList {

    if { [template::element exists $form_name $param] } {
      set $param [template::element get_value $form_name $param]

      
      if { ! [string equal [set $param] {}] } {
	# include the parameter if it is not null
	lappend params [db_map cont_new_item_non_null_params]

      } else {
        lappend params [db_map cont_new_item_def_params]
      }
    }
  }
  # RBM: FIX ME! In all PG content_item__new functions, relation_tag
  #      is set to NULL. Is that ok?
  
  # Use the correct relation tag, if specified
  if { [template::element exists $form_name relation_tag] } {
    set relation_tag [template::element get_value $form_name relation_tag]
      set rel_tag [string trim [db_map cont_new_item_rel_tag]]
      
    if{ $rel_tag != "null" } {
	# The content_item__new PG functions don't take relation_tag as
	# argument. So I made it so the PG .xql returns null, and the element
	# is not included in the list. But the Oracle one is, if it exists.
	
	lappend params $rel_tag
    }
  }

  set sql 

  db_transaction {
      db_exec_plsql create_new_content_item "
        begin 
          :item_id := content_item.new( [join $params ","] );
        end;" -bind item_id
      
      add_revision $form_name $tmpfile
  }

  # flush the sitemap folder listing cache
  #if { [template::element exists $form_name parent_id] } {
  #    set parent_id [template::element get_value $form_name parent_id]
  #    if { $parent_id == [cm::modules::sitemap::getRootFolderID] } {
  #      set parent_id ""
  #    }
  #    cms_folder::flush sitemap $parent_id
  #}

  return $item_id
}

# @public add_revision

# Create a new revision for an existing item based on a valid form
# submission.  Queries for attribute names and inserts a row into the
# attribute input view for the appropriate content type.  Inserts the
# contents of a file into the content column of the cr_revisions table
# for the revision as well.  

# @param form_name Name of the form from which to obtain attribute
# values.  The form should include an item_id and revision_id.

# @param tmpfile Name of the temporary file containing the content to
# upload.

ad_proc content::add_revision { form_name { tmpfile "" } } {

  # initialize an ns_set to hold bind values
  set bind_vars [ns_set create]

  # get the item_id and revision_id and content_method
  template::form get_values $form_name item_id revision_id content_method
  ns_set put $bind_vars item_id $item_id
  ns_set put $bind_vars revision_id $revision_id

  # query for content_type and table_name
  template::query addrev_get_content_type info onerow "
    select object_type content_type, table_name
    from acs_object_types
    where object_type = (select content_type from cr_items 
                         where item_id = :item_id)"

  set insert_statement [attribute_insert_statement \
	  $info(content_type) $info(table_name) $bind_vars $form_name]

  # if content exists, prepare it for insertion
  if { [template::element exists $form_name content] } {
      set filename [template::element get_value $form_name content]
      set tmpfile [prepare_content_file $form_name]
  } else { 
      set filename ""
  }

  add_revision_dml $insert_statement $bind_vars $tmpfile $filename

  # flush folder listing for item's parent because title may have changed
  #template::query parent_id onevalue "
  #  select parent_id from cr_items where item_id = :item_id" 
  #
  # if { $parent_id == [cm::modules::sitemap::getRootFolderID] } {
  #    set parent_id ""
  #}
  #cms_folder::flush sitemap $parent_id
}

# @private attribute_insert_statement 

# Prepare the insert statement into the attribute input view for a new
# revision (see the content repository documentation for details about
# the view).

# @param content_type The content type of the item for which a new
# revision is being prepared.

# @param table_name The storage table of the content type.

# @param bind_vars The name of an ns_set in which to store the
# attribute values for the revision.  (Typically duplicates the contents
# of [ns_getform].

# @param form_name The name of the ATS form object used to process the
# submission.

ad_proc content::attribute_insert_statement { 
  content_type table_name bind_vars form_name } {

  # get creation_user and creation_ip
  set creation_user [User::getID]
  set creation_ip [ns_conn peeraddr]
  ns_set put $bind_vars creation_user $creation_user
  ns_set put $bind_vars creation_ip $creation_ip


  # initialize the column and value list 
  set columns [list item_id revision_id creation_user creation_ip]
  set values [list :item_id :revision_id :creation_user :creation_ip]

  # query for attribute names and datatypes
  foreach attribute [get_attributes $content_type attribute_name datatype] { 

    set attribute_name [lindex $attribute 0]
    set datatype [lindex $attribute 1]

    # get the form value
    if { [template::element exists $form_name $attribute_name] } {

      set value [template::element get_value $form_name $attribute_name]

      # Convert dates to linear "YYYY MM DD HH24 MI SS" format
      if { [string equal $datatype date] } {
        set value [template::util::date get_property linear_date $value]
      }
      
      if { ! [string equal $value {} ] } {

        ns_set put $bind_vars $attribute_name $value

        lappend columns $attribute_name
        lappend values [get_sql_value $attribute_name $datatype]
      }
    }
  }

  set insert_statement "insert into ${table_name}i 
    ( [join $columns ","] ) values ( [join $values ","] )"

  return $insert_statement
}

# @private add_revision_dml 

# Perform the DML to insert a revision into the appropriate input view.

# @param statement The DML for the insert statement, specifying a bind
# variable for each column value.

# @param bind_vars An ns_set containing the values for all bind variables.

# @param tmpfile The server-side name of the file containing the body of the 
# revision to upload into the content BLOB column of cr_revisions.

# @param filename The client-side name of the file containing the body of 
# the revision to upload into the content BLOB column of cr_revisions

# @see add_revision

ad_proc content::add_revision_dml { statement bind_vars tmpfile filename } {

  db_transaction {

      db_dml $statement -bind $bind_vars

      if { ![string equal $tmpfile {}] } {

	  set revision_id [ns_set get $bind_vars revision_id]
	  upload_content $revision_id $tmpfile $filename
      
      } 
  }
}

# @private upload_content

# Inserts content into the database from an uploaded file.
# Does automatic mime_type updating
# Parses text/html content and removes <body></body> tags

# @param revision_id The revision to which the content belongs

# @param tmpfile The server-side name of the file containing the body of the 
# revision to upload into the content BLOB column of cr_revisions.

# @param filename The client-side name of the file containing the body of 
# the revision to upload into the content BLOB column of cr_revisions

ad_proc content::upload_content { revision_id tmpfile filename } {

    # if it is HTML then strip out the body
    set mime_type [ns_guesstype $filename]
    if { [string equal $mime_type text/html] } {
	set text [template::util::read_file $tmpfile]
	if { [regexp {<body[^>]*>(.*?)</body>} $text x body] } {
            set fd [open $tmpfile w]
            puts $fd $body
            close $fd
	}
    }
    
    # upload the file into the revision content

    db_dml update_cr_revisions "
      update cr_revisions 
      set content = empty_blob() where revision_id = :revision_id
      returning content into :1" -blob_files $tmpfile

    # update mime_type to match the file 
    set mime_sql "
      update cr_revisions 
        set mime_type = :mime_type 
        where revision_id = :revision_id"
    
    if { [catch {db_dml update_mime_sql $mime_sql} errmsg] } {
	#  if it fails, use user submitted mime_type
	ns_log notice "form-procs - add_revision_dml - using user mime_type 
	  instead of guessed mime type = $mime_type"
    }

    # delete the tempfile
    ns_unlink $tmpfile

}




# @private get_sql_value

# Return the sql statement for a column value in an insert or update
# statement, using a bind variable for the actual value and wrapping it
# in a conversion function where appropriate.  

# @param name The name of the column and bind variable (they should be
# the same).

# @param datatype The datatype of the column.

ad_proc content::get_sql_value { name datatype } {

  switch $datatype {
      date { set wrapper [db_map string_to_timestamp] }
    default { set wrapper ":$name" }
  }

  return $wrapper
}

# @private prepare_content_file

# Looks for an element named "content" in a form and prepares a
# temporarily file in UTF-8 for uploading to the content repository.
# Checks for a query variable named "content.tmpfile" to distinguish
# between file uploads and text entry.  If the type of the file is
# text, then ensures that is in UTF-8.  Does nothing if the uploaded
# file is in binary format.

# @param form_name  The name of the form object in which content was submitted.

# @return The path of the temporary file containing the content, or an empty
#         string if the form does not include a content element or the value
#         of the element is null.

ad_proc content::prepare_content_file { form_name } {
  
  if { ! [template::element exists $form_name content] } { return "" }

  template::form get_values $form_name content

  # check for content.tmpfile
  set tmpfile [ns_queryget content.tmpfile]
  set is_text 0

  if { ! [string equal $tmpfile {}] } {

    # check for a text file based on the extension (not ideal)
    if { [regexp {\.(htm|html|txt)$} $content] } {
      ns_log Notice "Converting text file $content to UTF-8..."
      set content [template::util::read_file $tmpfile]
      set is_text 1
    }

  } else {
    
    # no temporary file so content contains text
    set is_text 1
  }

  if { $is_text && ! [string equal $content {}] } {
    set tmpfile [string_to_file $content]
  }

  return $tmpfile
}

# @private string_to_file

# Write a string in UTF-8 encoding to of temp file so it can be
# uploaded into a BLOB (which is blind to character encodings).
# Returns the name of the temp file.

# @param s The string to write to the file.

ad_proc content::string_to_file { s } {

  set tmp_file [ns_tmpnam]

  set fd [open $tmp_file w]

  fconfigure $fd -encoding utf-8

  puts $fd $s
 
  close $fd

  return $tmp_file
}

# Form preparation procs

namespace eval content {

  variable columns
  set columns [list object_type sort_order attribute_name param_type \
      param_source value \
      pretty_name widget param param_is_required widget_is_required \
      is_html default_value datatype]
}

# @public new_item_form

# Adds elements to an ATS form object for creating an item and its
# initial revision.  If the form does not already exist, creates the
# form object and sets its enctype to multipart/form-data to allow for
# text entries greater than 4000 characters.

# @option form_name    	 The name of the ATS form object.  Defaults to 
#                      	 "new_item".
# @option content_type 	 The content_type of the item.  Defaults to
#                      	 "content_revision".
# @option content_method The method to use for uploading the content body.
#                        Valid values are "no_content", "text_entry", 
#                        and "file_upload".
#                      	 If the content type allows text, defaults to
#                      	 text entry, otherwise defaults to file upload.
# @option parent_id    	 The item ID of the parent.  Defaults to null (Parent
#                      	 is the root folder).
# @option name         	 The default name of the item.  Default is an empty 
#                      	 string (User must supply name).
# @option attributes   	 A list of attribute names for which to create form
#                      	 elements.
# @option action       	 The URL to which the form should redirect following
#                      	 a successful form submission.

ad_proc content::new_item_form { args } {

  array set opts [list form_name new_item content_type content_revision \
      parent_id {} name {} content_method {}]
  template::util::get_opts $args

  if { ! [template::form exists $opts(form_name)] } {
      template::form create $opts(form_name) \
	      -html { enctype multipart/form-data }
  }


  set name $opts(name)
  set form_name $opts(form_name)

  template::element create $opts(form_name) name \
	  -datatype filename \
	  -html { maxlength 400 } \
	  -widget text \
	  -label Name

  template::element create $opts(form_name) parent_id \
	  -datatype integer \
	  -widget hidden \
	  -optional

  # ATS doesn't like "-value -100" so use set_value to get around it
  template::element set_value $opts(form_name) parent_id $opts(parent_id)

  template::element create $opts(form_name) content_type \
	  -datatype keyword \
	  -widget hidden \
	  -value $opts(content_type)

  add_revision_form -form_name $opts(form_name) \
	  -content_type $opts(content_type) \
	  -content_method $opts(content_method)

  if { [template::form is_request $opts(form_name)] } {

      set item_id [get_object_id]
      template::element set_properties $opts(form_name) item_id -value $item_id

      if { [template::util::is_nil name] } {
	template::element set_value $opts(form_name) name "item$item_id"
      } else {
	template::element set_value $opts(form_name) name $name
      }
  }

  if { [info exists opts(action)] && \
	  [template::form is_valid $opts(form_name)] } {
      new_item $opts(form_name)
      template::forward $opts(action)
  }
}

# @public add_revision_form

# Adds elements to an ATS form object for adding a revision to an
# existing item.  If the item already exists, element values default a
# previous revision (the latest one by default).  If the form does not
# already exist, creates the form object and sets its enctype to
# multipart/form-data to allow for text entries greater than 4000
# characters.

# @option form_name      The name of the ATS form object.  Defaults to 
#                        "new_item".
# @option content_type   The content_type of the item.  Defaults to
#                        "content_revision".
# @option content_method The method to use for uploading the content body.
#                        If the content type is text, defaults to
#                        text entry, otherwise defaults to file upload.
# @option item_id        The item ID of the revision.  Defaults to null 
#                        (item_id must be set by the calling code).
# @option revision_id    The revision ID from which to draw default values.  
#                        Defaults to the latest revision
# @option attributes     A list of attribute names for which to create form
#                        elements.
# @option action         The URL to which the form should redirect following
#                        a successful form submission.

ad_proc content::add_revision_form { args } {

  array set opts [list form_name add_revision content_type content_revision \
      item_id {} content_method {} revision_id {}]
  template::util::get_opts $args

  if { [string equal $opts(content_method) {}] } {
    set opts(content_method) [get_default_content_method $opts(content_type)]
  }

  if { ! [template::form exists $opts(form_name)] } {
    template::form create $opts(form_name) -html { enctype multipart/form-data }
  }

  if { ! [template::element exists $opts(form_name) item_id] } {
    template::element create $opts(form_name) item_id -datatype integer \
	-widget hidden -value $opts(item_id)    
  }

  if { ! [template::element exists $opts(form_name) revision_id] } {
    template::element create $opts(form_name) revision_id -datatype integer \
	-widget hidden 
  }

  set attributes [add_attribute_elements $opts(form_name) $opts(content_type)]

  add_content_element $opts(form_name) $opts(content_method)

  if { [template::form is_request $opts(form_name)] } {

    set revision_id [get_object_id]
    template::element set_properties $opts(form_name) revision_id -value $revision_id

    if { [string equal $opts(revision_id) {}] } {
      set opts(revision_id) [get_latest_revision $opts(item_id)]
    }

    if { ! [string equal $opts(revision_id) {}] } {
      set_attribute_values $opts(form_name) $opts(content_type) \
          $opts(revision_id) $attributes
    }

    # if the content_method is text_entry, then retrieve the latest
    # content from the database.
    set revision_id $opts(revision_id)
    if { ![template::util::is_nil revision_id] } {
	if { [string equal $opts(content_method) text_entry] } {
	    set_content_value $opts(form_name) $opts(revision_id)
	}
    }
  }

  if { [info exists opts(action)] && [template::form is_valid $opts(form_name)] } {

    set tmpfile [prepare_content_file $opts(form_name)]

    add_revision $opts(form_name) $tmpfile
    template::forward $opts(action)
  }
}

# @public add_attribute_elements

# Add form elements to an ATS form object for all attributes of a
# content type.

# @param form_name   	 The name of the ATS form object to which objects
#                    	 should be added.
# @param content_type	 The content type keyword for which attribute
#                    	 widgets should be added.
# @param revision_id     The revision from which default values should be
#                        queried
# @return The list of attributes that were added.

ad_proc content::add_attribute_elements { form_name content_type \
  { revision_id "" } } {

  # query for attributes in the appropriate order
  set attribute_list [get_attributes $content_type object_type attribute_name]

  # get a lookup of object_types
  foreach row $attribute_list { 
    set type_lookup([lindex $row 0]) 1 
  }

  set attribute_data [eval get_type_attribute_params [array names type_lookup]]

  set attribute_names [list]
  array set attributes_by_type $attribute_data

  foreach row $attribute_list { 

    set object_type [lindex $row 0]
    set attribute_name [lindex $row 1]

    # look up attribute
    if { ! [info exists attributes_by_type($object_type)] } { continue }

    array set attributes $attributes_by_type($object_type)
    
    if { ! [info exists attributes($attribute_name)] } { continue }

    add_attribute_element $form_name $content_type $attribute_name \
	$attributes($attribute_name)

    lappend attribute_names $attribute_name
  }

  if { ![template::util::is_nil revision_id] } {
      if { [template::form is_request $form_name] } {

	  # set default values for attribute elements
	  set_attribute_values $form_name \
		  $content_type $revision_id $attribute_names
      }
  }

  return $attribute_names
}

# @public add_attribute_element

# Add a form element (possibly a compound widget) to an ATS form object.
# for entering or editing an attribute value.

# @param form_name 	   The name of the ATS form object to which the element
#                  	   should be added.
# @param content_type      The content type keyword to which this attribute
#                          belongs.
# @param attribute 	   The name of the attribute, as represented in the
#                  	   attribute_name column of the acs_attributes table.
# @param attribute_data    Optional nested list of parameter data for the
#                          the attribute (generated by get_attribute_params).

ad_proc content::add_attribute_element { 
  form_name content_type attribute { attribute_data "" } } {

  variable columns

  set command [list "template::element" create $form_name $attribute]

  if { [string equal $attribute_data {}] } {
    set attribute_data [get_attribute_params $content_type $attribute]
  }

  array set is_html $attribute_data


  # if there is a false entry for is_html, compile element options
  if { [info exists is_html(f)] } {

    foreach values $is_html(f) {

      template::util::list_to_array $values param $columns
      lappend command -$param(param) \
        [get_widget_param_value param $content_type]
    }
  }

  # if there is a true entry for is_html, compile html options
  if { [info exists is_html(t)] } {

    foreach values $is_html(t) {

      template::util::list_to_array $values param $columns
      lappend html_params $param(param) \
        [get_widget_param_value param $content_type]
    }
    lappend command -html $html_params
  }

  # if there is a null entry for is_html, the widget has no parameters
  set null {{}}
  set null2 {}
  if { [info exists is_html($null)] || [info exists is_html($null2)] } {

    set values [lindex $is_html($null) 0]
    template::util::list_to_array $values param $columns
  }


  # special case - the search widget
  #if { [string equal $param(widget) search] } {
  #    set param(datatype) search
  #}


  # use any set of values for label and optional flag
  lappend command -label $param(pretty_name) -widget $param(widget) \
	  -datatype $param(datatype)
  
  if { [string equal $param(widget_is_required) f] } {
      lappend command -optional
  }

  #ns_log notice "--------------- command = $command"
  eval $command
}

# @public add_content_element

# Adds a content input element to an ATS form object.

# @param form_name      The name of the form to which the object should be
#                       added.
# @param content_method One of no_content, text_entry or file_upload
 
ad_proc content::add_content_element { 
  form_name content_method { section_name "Content" } } {

  template::element create $form_name content_method \
	  -datatype keyword \
	  -widget hidden \
	  -value $content_method

  switch $content_method {

    text_entry {

      template::form section $form_name $section_name
      template::element create $form_name content -widget textarea -label {} \
	  -datatype text -html { cols 80 rows 20 wrap physical } 

      if { [template::element exists $form_name mime_type] && \
	  [template::element exists $form_name content_type] } {

	  set content_type \
		  [template::element get_value $form_name content_type]

	  # change mime types select widget to only allow text MIME types
	  template::query get_text_mime_types text_mime_types multilist "
	    select
	      label, map.mime_type as value
	    from
	      cr_mime_types types, cr_content_mime_type_map map
	    where
	      types.mime_type = map.mime_type
	    and
	      map.content_type = :content_type
	    and
	      lower(types.mime_type) like ('text/%')
	    order by
	      label"
	      
	  template::element set_properties $form_name mime_type \
		  -options $text_mime_types
      }


    }

    file_upload {

	template::form section $form_name $section_name
	template::element create $form_name content -widget file \
		-label "Upload Content" \
		-datatype text

    }

  }
}

# @public add_child_relation_element
#
# Add a select box listing all valid child relation tags.
# The form must contain a parent_id element and a content_type element.
# If the elements do not exist, or if there are no valid relation tags,
# this proc does nothing. 
#
# @param form_name  The name of the form 
#
# @option section {<i>none</i>} If present, creates a new form section
#   for the element. 
#
# @option label {Child relation tag} The label for the element

proc content::add_child_relation_element { form_name args } {
  
  # Process parameters

  template::util::get_opts $args

  if { ![template::util::is_nil opts(label)] } {
    set label $opts(label)
  } else {
    set label "Child relation tag"
  }

  # Check form elements

  if { [template::element exists $form_name content_type] } {
    set content_type [template::element get_value $form_name content_type]
  } else {
    return
  }

  if { [template::element exists $form_name parent_id] } {
    set parent_id [template::element get_value $form_name parent_id]
  } else {
    return
  }

  # Get the parent type. If the parent is not an item, abort
  template::query get_parent_type parent_type onevalue "
    select content_type from cr_items 
    where item_id = :parent_id
   " -cache "item_content_type $parent_id" -persistent \
     -timeout 3600

  if { [template::util::is_nil parent_type] } {
    return
  }

  # Get a multilist of all valid relation tags
  template::query get_all_valid_relation_tags options multilist "
    select 
      relation_tag as label, relation_tag as value 
    from 
      cr_type_children c
    where
      content_item.is_subclass(:parent_type, c.parent_type) = 't'
    and
      content_item.is_subclass(:content_type, c.child_type) = 't'
    and
      content_item.is_valid_child(:parent_id, c.child_type) = 't'
  " 

  if { [template::util::is_nil options] } {  
    return
  }

  # Create the section, if specified
  if { ![template::util::is_nil opts(section)] } {
    template::query get_parent_title parent_title onevalue "
      select content_item.get_title(:parent_id) from dual
    "

    if { ![template::util::is_nil parent_title] } {
      template::form section $form_name "Relationship to $parent_title"
    }
  }

  # Create the element
  set options [concat [list [list "(Default)" ""]] $options]

  template::element create $form_name relation_tag -label $label \
    -datatype text -widget select -options $options -optional
}


# @private get_widget_param_value

# Utility procedure to return the value of a widget parameter

# @param array_ref     The name of an array in the calling frame
#                      containing parameter data selected from the form 
#                      metadata.
# @param content_type  The current content type; defaults to content_revision

ad_proc content::get_widget_param_value { 
  array_ref {content_type content_revision}
} {

  upvar $array_ref param
  set value ""

  # a datatype of enumeration is a special case 

  if { [string equal $param(datatype) enumeration] } {

    set value [get_attribute_enum_values $param(attribute_id)]

  } else {

    switch $param(param_source) {

      eval {
	set value [eval $param(value)]
      }
      query {
	#set content_type content_revision
	set item_id {}
	template::query set_content_values value $param(param_type) $param(value)
      }
      default {
	set value $param(value)
	  if { [template::util::is_nil value] } {
	      set value $param(default_value)
	  }
      }
    }
    # end switch
  }

  return $value
}

# @private get_type_attribute_params

# Query for attribute form metadata

# @param args Any number of object types

# @return A list of attribute parameters nested by object_type, attribute_name
#         and the is_html flag.  For attributes with no parameters,
#         there is a single entry with is_html as null.

ad_proc content::get_type_attribute_params { args } {

  variable columns

  foreach object_type $args {
    lappend in_list [ns_dbquotevalue $object_type]
  }

  template::query gtap_get_attribute_data attribute_data nestedlist "
    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext x
    where
      object_type in ( [join $in_list ","] )
  " -groupby { object_type attribute_name is_html }

  return $attribute_data
}

# @private get_attribute_params

# Query for parameters associated with a particular attribute

# @param content_type      The content type keyword to which this attribute
#                          belongs.
# @param attribute_name	   The name of the attribute, as represented in the
#                  	   attribute_name column of the acs_attributes table.

ad_proc content::get_attribute_params { content_type attribute_name } {

  variable columns

  template::query gap_get_attribute_data attribute_data nestedlist "
    select
      [join $columns ","]
    from
      cm_attribute_widget_param_ext
    where
      object_type = :content_type
    and
      attribute_name = :attribute_name
  " -groupby { is_html }

  return $attribute_data
}

# @private set_attribute_values

# Set the default values for attribute elements in ATS form object
# based on a previous revision

# @param form_name         The name of the ATS form object containing
#                          the attribute elements.
# @param content_type      The type of item being revised in the form.
# @param revision_id       The revision ID from where to get the default values
# @param attributes        The list of attributes whose values should be set.

ad_proc content::set_attribute_values { form_name content_type revision_id \
    attributes } {

  if { [llength $attributes] == 0 } {
    set attributes [get_attributes $content_type]
  }

  # Assemble the list of columns to query, handling dates
  # correctly 

  set columns [list]
  set attr_types [list]  
  foreach attr $attributes {
    if { [template::element exists $form_name $attr] } {
      set datatype [template::element get_property $form_name $attr datatype]
      if { [string equal $datatype date] } {
	  lappend columns [db_map timestamp_to_string]
      } else {
        lappend columns $attr
      }

      lappend attr_types [list $attr $datatype]
    }
  }
      
  # Query for values from a previous revision

  template::query get_previous_version_values values onerow  "
    select 
      [join $columns ", "] 
    from 
      [get_type_info $content_type table_name]x
    where 
      revision_id = :revision_id
  "

  # Set the form values, handling dates with the date acquire function
  foreach pair $attr_types {
    set element_name [lindex $pair 0]
    set datatype [lindex $pair 1]
 
    if { [info exists values($element_name)] } {

      if { [string equal $datatype date] } {
         set value [template::util::date acquire \
             sql_date $values($element_name)]
      } else {
         set value $values($element_name)
      }
 
      template::element set_properties $form_name $element_name \
        -value $value -values [list $value]
    }
  }
    
}

# @private set_content_value

# Set the default value for the content text area in an ATS form object
# based on a previous revision

# @param form_name         The name of the ATS form object containing
#                          the content element.
# @param revision_id       The revision ID of the content to revise

ad_proc content::set_content_value { form_name revision_id } {

  set content [get_content_value $revision_id]

  template::element set_properties $form_name content -value $content
}

# @private get_default_content_method

# Gets the content input method most appropriate for an content type,
# based on the MIME types that are registered for that content type.

# @param content_type  The content type for which an input method is needed.

ad_proc content::get_default_content_method { content_type } {

  template::query count_mime_type is_text onevalue "select count(*) from cr_content_mime_type_map
    where content_type = :content_type and mime_type like 'text/%'"

  if { $is_text > 0 } {
    set content_method text_entry
  } else {
    set content_method file_upload
  }

  return $content_method
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# Procedure wrappers for basic ACS Object and Content Repository queries 
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

# @private get_type_info

# Return specified columns from the acs_object_types table.

# @param object_type Object type key for which info is required.
# @param ref         If no further arguments, name of the column value to
#                    return.  If further arguments are specified, name of 
#                    the array in which to store info in the calling
# @param args        Column names to query.

ad_proc content::get_type_info { object_type ref args } {

  if { [llength $args] == 0 } {

    template::query get_type_info_1 info onevalue "
      select 
        $ref
      from 
        acs_object_types 
      where 
        object_type = :object_type"

    return $info

  } else {

    template::query get_type_info_2 $ref onerow "
      select 
        [join $args ","]
      from 
        acs_object_types 
      where 
        object_type = :object_type" -uplevel
  }
}

# @public get_object_id

# Grab an object ID for creating a new ACS object.

ad_proc content::get_object_id {} {

  return [db_nextval select acs_object_id_seq]
}

ad_proc content::get_content_value { revision_id } {

  db_transaction {
      db_exec_plsql gcv_get_revision_id {
	  begin
	    content_revision.to_temporary_clob(:revision_id);
	  end;
      }

      # Query for values from a previous revision

      template::query gcv_get_previous_content content onevalue "
      select 
        content
      from 
        cr_content_text
      where 
        revision_id = :revision_id"

  }

  return $content
}

# @private get_attributes

# Returns columns from the acs_attributes table for all attributes
# associated with a content type.

# @param content_type The name of the content type (ACS Object Type)
# for which to obtain the list of attributes.
# @param args Names of columns to query.  If no columns are specified,
# returns a simple list of attribute names.

ad_proc content::get_attributes { content_type args } {

  if { [llength $args] == 0 } {
    set args [list attribute_name]
  }

  ### RBM: FIX ME (aD left this note. Probably should be fixed).
  ### HACK ! What the hell is "ldap dn" ?

  if { [llength $args] == 1 } {
    template::query ga_get_attributes attributes onelist ""
  } else {
    template::query attributes multilist ""
  }

  return $attributes
}

# @public get_attribute_enum_values

# Returns a list of { pretty_name enum_value } for an attribute of
# datatype enumeration.

# @param attribute_id   The primary key of the attribute as in the
#                       attribute_id column of the acs_attributes table.

ad_proc content::get_attribute_enum_values { attribute_id } {

  template::query gaev_get_enum_values enum multilist "
           select
	     nvl(pretty_name,enum_value), 
	     enum_value
	   from
	     acs_enum_values
	   where
	     attribute_id = :attribute_id
	   order by
	     sort_order"


  return $enum
}

# @public get_latest_revision

# Get the ID of the latest revision for the specified content item.

# @param item_id  The ID of the content item.

ad_proc content::get_latest_revision { item_id } {

  template::query glr_get_latest_revision latest_revision onevalue "
    select content_item.get_latest_revision(:item_id) from dual"

  return $latest_revision
}


# @public add_basic_revision

# Create a basic new revision using the content_revision PL/SQL API.

# @param item_id
# @param revision_id
# @param title

# @option description
# @option mime_type
# @option text
# @option tmpfile

ad_proc content::add_basic_revision { item_id revision_id title args } {

  template::util::get_opts $args

  set creation_ip [ns_conn peeraddr]
  set creation_user [User::getID]

  set sql [db_map abr_new_revision_title]
             item_id       => content_symlink.resolve(:item_id),
         revision_id   => :revision_id,
         creation_date  => sysdate,
         creation_ip   => :creation_ip,
         creation_user => :creation_user

  foreach param { description publish_date mime_type nls_language text } {

    if { [info exists opts($param)] } {
      set $param $opts($param)
	append sql [db_map abr_new_revision_$param]", $param => :$param"
    } else {
	switch $param {
	    "description" 
  }

  append sql "); end;"

  set db [template::begin_db_transaction]

  ns_ora exec_plsql_bind $db $sql revision_id

  if { [info exists opts(tmpfile)] } {

    update_content_from_file $revision_id $opts(tmpfile)
  }

  template::end_db_transaction
}

# @private update_content_from_file

# Update the BLOB column of a revision with the contents of a file

# @param revision_id The object ID of the revision to update.
# @param tmpfile     The name of a temporary file containing the content.
#                    The file is deleted following the update.

proc content::update_content_from_file { revision_id tmpfile } {

  set file_upload "update cr_revisions 
    set content = empty_blob() where revision_id = :revision_id
    returning content into :1"

  set db [template::get_db_handle]
  ns_ora blob_dml_file_bind $db $file_upload [list 1] $tmpfile

  ns_unlink $tmpfile
}



# @public copy_latest_content

# Update the BLOB column of one revision with the content of another revision

# @param revision_id_src  The object ID of the revision with the content to be 
# copied.

# @param revision_id_dest  The object ID of the revision to be updated.
# copied.

proc content::copy_content { revision_id_src revision_id_dest } {

    set db [template::begin_db_transaction]

    # copy the content from the source to the target
    ns_ora dml $db "
      begin
      content_revision.content_copy (
          revision_id      => :revision_id_src,
          revision_id_dest => :revision_id_dest
      );
      end;"

    # fetch the mime_type of the source revision
    template::query mime_type onevalue "
      select mime_type from cr_revisions where revision_id = :revision_id_src
    " -db $db

    # copy the mime_type to the destination revision
    ns_ora dml $db "
     update cr_revisions
       set mime_type = :mime_type
       where revision_id = :revision_id_dest"


    template::end_db_transaction
}



# @public add_content

# Update the BLOB column of a revision with content submitted in a form

# @param revision_id  The object ID of the revision to be updated.

proc content::add_content { form_name revision_id } {
    
    # if content exists, prepare it for insertion
    if { [template::element exists $form_name content] } {
	set filename [template::element get_value $form_name content]
	set tmpfile [prepare_content_file $form_name]
    } else { 
	set filename ""
	set tmpfile ""
    }

    if { ![string equal $tmpfile {}] } {
	set db [template::begin_db_transaction]
	upload_content $db $revision_id $tmpfile $filename
	template::end_db_transaction
    } else {
	# no content
    }
}



# @public validate_name

# Make sure that name is unique for the folder

# @param form_name The name of the form (containing name and parent_id)
# @return 0 if there are items with the same name, 1 otherwise
proc content::validate_name { form_name } {
    set name [template::element get_value $form_name name] 
    set parent_id [template::element get_value $form_name parent_id]

    if { [template::util::is_nil parent_id] } {
	template::query same_name_count onevalue "
	  select
	    count(1)
	  from
            cr_items
          where
	    name = :name"
    } else {
	template::query same_name_count onevalue "
	  select
            count(1)
          from
            cr_items
          where
            name = :name
          and 
            parent_id = :parent_id"
    }

    if { $same_name_count > 0 } {
	return 0
    } else {
	return 1
    }
}
