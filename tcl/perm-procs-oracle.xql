<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="content::perm_form_generate.">      
      <querytext>
      
    set is_request [form is_request $perm_form_name]
   
    
    
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
  
      </querytext>
</fullquery>

 
<fullquery name="content::perm_form_generate.">      
      <querytext>
      

    if { [form is_valid $perm_form_name] } {

      set user_id [User::getID]

      form get_values $perm_form_name object_id grantee_id pf_is_recursive
      set permission_values [element get_values $perm_form_name pf_boxes]

      db_transaction {

	  
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
  
      
      content::check_access $object_id "cm_read" \
        -user_id $user_id -refresh

    }
  
      </querytext>
</fullquery>

 
<fullquery name="content::check_access.ca_get_perm_list">      
      <querytext>
      
    select 
      p.privilege,
      cms_permission.permission_p (
        :object_id, :user_id, p.privilege
      ) as is_granted
    from 
      acs_privileges p
      </querytext>
</fullquery>

 
<fullquery name="content::check_access.ca_get_msg_info">      
      <querytext>
      
	select 
	  acs_object.name(:object_id) as obj_name, 
	  pretty_name as perm_name
	from 
	  acs_privileges
	where 
	  privilege = :privilege
      </querytext>
</fullquery>

<partialquery name="content::perm_form_generate.pfg_get_permission_boxes">
	<querytext>

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

	</querytext>
</partialquery>

<partialquery name="content::perm_form_process.pfp_grant_permission_1">
	<querytext>
                     begin 
	               cms_permission.grant_permission (
		         item_id => :object_id, 
		         holder_id => :user_id,
		         privilege => :privilege, 
		         recepient_id => :grantee_id,
                         is_recursive => :pf_is_recursive
	               );
	             end;

	</querytext>
</partialquery>

<partialquery name="content::perm_form_process.pfp_revoke_permission_1">
	<querytext>
                     begin 
     	               cms_permission.revoke_permission (
		         item_id => :object_id, 
		         holder_id => :user_id,
		         privilege => :privilege, 
		         revokee_id => :grantee_id,
                         is_recursive => :pf_is_recursive
	               );
	             end;

	</querytext>
</partialquery>

</queryset>
