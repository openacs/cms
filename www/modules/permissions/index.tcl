request create
request set_param object_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param parent_id -datatype keyword -optional
request set_param return_url -datatype text -optional
request set_param passthrough -datatype text -optional

#set passthrough "id=$object_id&mount_point=$mount_point&parent_id=$parent_id"

set user_id [User::getID]


# Determine if the user can modify permissions on this object
# Should it dump a user to an error page if no access ?
#content::check_access $id "cm_perm" -db $db -user_id $user_id \
#  -parent_id $parent_id -mount_point $mount_point

# Determine if the user is the site wide admin, and if he has the rights to \
# modify permissions at all
content::check_access $object_id "cm_examine" \
  -user_id $user_id -mount_point $mount_point -parent_id $parent_id

if { ![string equal $user_permissions(cm_perm) t] } {
  return
}

# Get a list of permissions that users have on the item
template::query get_permissions permissions multirow "
  select * from ( 
    select 
      p.pretty_name, 
      p.privilege, 
      u.party_id as grantee_id,
      n.first_names || ' ' || n.last_name as grantee_name,
      u.email
    from 
      acs_permissions per, acs_privileges p, parties u,
      persons n,
      (select object_id from acs_objects 
	 connect by prior context_id = object_id 
		and prior security_inherit_p = 't'
	 start with object_id = :object_id) o
    where
      per.privilege = p.privilege
    and
      per.grantee_id = u.party_id
    and
      per.object_id = o.object_id
    and
      u.party_id = n.person_id
  union
    select
      p.pretty_name, p.privilege, 
      -1 as grantee_id, 'All Users' as grantee_name, '&nbsp;' as email 
    from
      acs_permissions per, acs_privileges p, parties u
    where
      u.party_id = -1
    and
      per.object_id = :object_id
    and
      per.privilege = p.privilege
    and
      per.grantee_id = u.party_id
  ) order by
    grantee_name, privilege
  " 


# Create a URL passthrough stub to access permissions
set perms_url_extra "return_url=$return_url&passthrough=$passthrough&object_id=$object_id"


set header "\[ <a href=\"../permissions/permission-grant?$perms_url_extra\">Grant</a> \] more permissions to a marked user"
