##############################################
#
# Functions dealing with permissions
#
##############################################

# Redirect the user to an error message
# In the future, have this procedure produce a custom, internationalized
# error message, or something

# Will pick up mount_point, id, parent_id if they exist in the calling
# frame

ad_proc content::show_error { 
  message {return_url {}} {passthrough {}}
} {
  
  if { [template::util::is_nil return_url] } {
    set return_url [ns_conn url]
  }

  foreach var { mount_point id parent_id } {
    upvar $var $var
    if { ![template::util::is_nil $var] } {
      lappend passthrough [list $var [set $var]]
    }
  }

  template::forward "[ad_conn package_url]error?[export_vars { message return_url passthrough}]"
}
  
# Query the datatbase for access, show the error page if
# no sufficient access is found. Set up an array
# called "user_permissions" in the calling frame, where the keys
# are permissions and the values are "t" or "f"
# Flags:
# -user_id <user_id>
# -mount_point <mount_point>
# -parent_id <parent_id>
# -return_url <return_url>
# -passthrough < { {name value} {name value} ... }
# -request_error: if present, use request error as opposed to error box
# -refresh: if present, update query cache

ad_proc content::check_access { object_id privilege args } { 

  # Set up the default options
  foreach varname { mount_point return_url parent_id passthrough } {
    set opts($varname) ""
  }

  template::util::get_opts $args 

  ns_log notice [array get opts]

  if { [template::util::is_nil opts(user_id)] } {
    set user_id [User::getID]
  } else {
    set user_id $opts(user_id)
  }  

  # Query the database, set up the array
  upvar user_permissions user_permissions

  set code [list template::query ca_get_perm_list perm_list multilist "
    select 
      p.privilege,
      cms_permission.permission_p (
        :object_id, :user_id, p.privilege
      ) as is_granted
    from 
      acs_privileges p" \
      -cache "content::check_access $object_id $user_id" -persistent \
      -timeout 300]
  if { [info exists opts(refresh)] } {
    lappend code "-refresh"
  }
  eval $code
    
  template::util::list_of_lists_to_array $perm_list user_permissions

  # If we have no permission to view this page, abort
  if { [string equal $user_permissions($privilege) f] } {
    foreach varname { mount_point return_url parent_id passthrough } {
      set $varname $opts($varname)
    }

    # See if the user is even logged in
    template::query ca_get_user_name user_name onevalue "
      select screen_name from users where user_id = :user_id
    " 

    if { [template::util::is_nil user_name] } {
      set msg "You are not logged in. Press Ok to go to the login screen."
      set return_url "[ad_conn package_url]signin"   
    } else {

      # Get the error message
      template::query ca_get_msg_info msg_info onerow "
	select 
	  acs_object.name(:object_id) as obj_name, 
	  pretty_name as perm_name
	from 
	  acs_privileges
	where 
	  privilege = :privilege" 

      if { ![info exists msg_info] } {
	set msg "Access Denied: no such privilege $privilege"
      } else {
	set msg "Access Denied: you do not possess the $msg_info(perm_name)"
	append msg " privilege on $msg_info(obj_name)"
      }
    }

    # Show the error message
    lappend passthrough [list mount_point $opts(mount_point)] \
                        [list parent_id $opts(parent_id)]

    # Display either the request error or redirect ot an error box
    if { [info exists opts(request_error)] } {
      template::request::error access_denied $msg
      return
    } else {
      content::show_error $msg $return_url $passthrough
    }

  }  

}

# Flush the cache used by check_access
ad_proc content::flush_access_cache { {object_id {}} } {
  template::query::flush_cache "content::check_access ${object_id}*"
}

# Generate a form for modifying permissions
# Requires object_id, grantee_id, user_id to be set in calling frame

ad_proc content::perm_form_generate { form_name_in {passthrough "" } } {

  upvar perm_form_name form_name
  set form_name $form_name_in

  # FIX ME
  set sql [db_map pfg_get_permission_boxes]
  upvar __sql sql
  
  uplevel {
    set is_request [form is_request $perm_form_name]
   
    # Get a list of all the possible permissions, along with a flag
    # to see if the user has the permission
    set permission_options [list]
    set permission_values  [list]

    template::query permission_boxes multirow $__sql "
      select 
	t.child_privilege as privilege, 
	lpad(' ', t.tree_level * 24, '&nbsp;') || 
          NVL(p.pretty_name, t.child_privilege) as label,
	cms_permission.permission_p(
	 :object_id, :grantee_id, t.child_privilege
	) as permission_p,
        cms_permission.permission_p (
	 :object_id, :grantee_id, t.privilege
	) as parent_permission_p
      from (
	select privilege, child_privilege, level as tree_level
	  from acs_privilege_hierarchy
	  connect by privilege = prior child_privilege
	  start with privilege = 'cm_root'
	) t, acs_privileges p
      where
	p.privilege = t.child_privilege
      and (
	cms_permission.has_grant_authority (
	  :object_id, :user_id, t.child_privilege
	) = 't' 
	or
	cms_permission.has_revoke_authority (
	  :object_id, :user_id, t.child_privilege, :grantee_id
	) = 't' 
      )
    " -eval {
      if { [string equal $row(parent_permission_p) f] } {
        lappend permission_options [list $row(label) $row(privilege)]
        if { [string equal $row(permission_p) t] && $is_request } {
          lappend permission_values $row(privilege)
        }
      }
    }

    # Only show checkboxes if the privilege is in pf_show_boxes
    # The join is just a hack for now
#    set pf_show_boxes [join $pf_show_boxes "|"]

    element create $perm_form_name object_id -label "Object ID" \
      -datatype integer -widget hidden -param

    element create $perm_form_name grantee_id -label "Grantee ID" \
      -datatype integer -widget hidden -param

    element create $perm_form_name pf_boxes -label "Permissions" \
      -datatype text -widget checkbox -options $permission_options \
      -values $permission_values -optional

    element create $perm_form_name pf_is_recursive \
      -label "Apply changes to child items and subfolders ?" \
      -datatype text \
      -widget radio -options { {Yes t} {No f} } -values { f }
  }
  
  foreach varname $passthrough {
    uplevel "element create $form_name $varname -label \"$varname\" \\
               -datatype text -widget hidden -value \$$varname -optional"
  }
  
}


# Process the permission form

ad_proc content::perm_form_process { form_name_in } {

  upvar perm_form_name form_name
  set form_name $form_name_in
  # FIX ME
  set sql_grant [db_map pfp_grant_permission_1]
  set sql_revoke [db_map pfp_revoke_permission_1]
  upvar __sql_grant sql_grant
  upvar __sql_revoke sql_revoke
  
  uplevel {

    if { [form is_valid $perm_form_name] } {

      set user_id [User::getID]

      form get_values $perm_form_name object_id grantee_id pf_is_recursive
      set permission_values [element get_values $perm_form_name pf_boxes]

      db_transaction {

	  # Assign checked permissions, unassign unchecked ones
	  foreach pair $permission_options {
	      set privilege [lindex $pair 1]
	      if { [lsearch $permission_values $privilege] >= 0 } {
		  template::query pfp_grant_permission grant_permission dml $__sql_grant "
                     begin 
	               cms_permission.grant_permission (
		         item_id => :object_id, 
		         holder_id => :user_id,
		         privilege => :privilege, 
		         recepient_id => :grantee_id,
                         is_recursive => :pf_is_recursive
	               );
	             end;"
	      } else {
		  template::query pfp_revoke_permission revoke_permission dml $__sql_revoke"
                     begin 
     	               cms_permission.revoke_permission (
		         item_id => :object_id, 
		         holder_id => :user_id,
		         privilege => :privilege, 
		         revokee_id => :grantee_id,
                         is_recursive => :pf_is_recursive
	               );
	             end;"
	      }
	  }

      }
  
      # Recache the permissions
      content::check_access $object_id "cm_read" \
        -user_id $user_id -refresh

    }
  }

}





