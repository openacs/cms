# This page should allow browsing of group components, with creation of
# new components.

# links:
# users-add.tcl (Add Users to this Group)

request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -value users
request set_param parent_id -datatype keyword -optional

# Determine if the user has admin privileges on the user module
set user_id [User::getID]
set module_id [cm::modules::get_module_id $mount_point]
template::query admin_p onevalue "
  select 
    cms_permission.permission_p (:module_id, :user_id, 'cm_admin')
  from
    dual" -cache "module_permission $module_id $user_id"

if { [string equal $admin_p t] } {
  set admin_url "make-admin?mount_point=$mount_point&parent_id=$parent_id&target_user_id="
}

template::query perm_p onevalue "
  select 
    cms_permission.permission_p (:module_id, :user_id, 'cm_perm')
  from
    dual" -cache "module_permission $module_id $user_id"


# Create all the neccessary URL params for passthrough
set passthrough "mount_point=$mount_point&parent_id=$parent_id"
set root_id [cm::modules::${mount_point}::getRootFolderID]


if { ![util::is_nil id] } {

  set current_id $id

  # Get info about the current group
  query info onerow "
    select 
      g.group_id, g.group_name, p.email, p.url,
      NVL((select 'f' from dual where exists (
            select 1 from acs_rels 
              where object_id_one = :id 
              and rel_type in ('composition_rel', 'membership_rel'))),
          't') as is_empty 
    from 
      groups g, parties p
    where
      g.group_id = :id
    and
      p.party_id = :id"

  set groups_query "
    select
      g.group_id, g.group_name,
      NVL(pg.email, '&nbsp;') as email,
      (select count(*) from group_member_map 
       where group_id = g.group_id) as user_count
    from 
      groups g, parties pg, acs_rels rg, composition_rels rc
    where
      g.group_id = pg.party_id
    and
      rg.object_id_one = :id
    and
      rg.object_id_two = g.group_id
    and
      rc.rel_id = rg.rel_id
    order by
      upper(g.group_name)" 

  set users_query "
    select
      u.user_id, ppu.first_names || ' ' || ppu.last_name as pretty_name,
      NVL(u.screen_name, '&nbsp;') as screen_name,
      pu.email, aru.member_state,
      aru.rel_id
    from
      users u, persons ppu, parties pu, 
      acs_rels ru, membership_rels aru
    where
      u.user_id = ppu.person_id
    and
      u.user_id = pu.party_id
    and
      ru.object_id_one = :id
    and
      ru.object_id_two = u.user_id
    and
      aru.rel_id = ru.rel_id
    and
      (aru.member_state <> 'deleted' or aru.member_state is null)
    order by
      upper(pretty_name)"

    set users_eval  {
      set state_html ""
      set the_pipe ""
      foreach pair { {Approved approved} {Rejected rejected} {Banned banned}} {

	set label [lindex $pair 0]
	set value [lindex $pair 1] 

	append state_html $the_pipe

	if { [string equal $row(member_state) $value] } {
	  append state_html "<b>$value</b>"
	} else {
	  append state_html "<a href=\"change-user-state?rel_id=$row(rel_id)&group_id=$id"
	  append state_html "&new_state=$value&mount_point=$mount_point&parent_id=$id\">"
	  append state_html "$value</a>"
	}

	set the_pipe "&nbsp;|&nbsp;"
      }

      set row(state_html) $state_html
    }

} else {

  set current_id $module_id

  # the everyone party
  query info onerow "
    select
      party_id group_id, 'All Users' as group_name, 
      email, url, 'f' as is_empty
    from
      parties
    where
      party_id = -1
  "

  #clipboard::get_bookmark_icon $clip $mount_point $info(group_id) info

  set groups_query "
    select
      g.group_id, g.group_name,
      NVL(pg.email, '&nbsp;') as email, 
      (select count(*) from group_member_map 
       where group_id = g.group_id) as user_count
    from 
      groups g, parties pg
    where
      g.group_id = pg.party_id
    and
      not exists (
        select 1 from acs_rels ar, composition_rels cr
        where ar.rel_id = cr.rel_id
        and ar.object_id_two = g.group_id)
    order by
      g.group_name"

  set users_query "
    select
      u.user_id, ppu.first_names || ' ' || ppu.last_name as pretty_name,
      NVL(u.screen_name, '&nbsp;') as screen_name,
      pu.email, '' as member_state,
      null as rel_id       
    from
      users u, persons ppu, parties pu
    where
      u.user_id = ppu.person_id
    and
      u.user_id = pu.party_id
    and
      not exists (
        select 1 from acs_rels ar, membership_rels mr
        where ar.rel_id = mr.rel_id
        and ar.object_id_two = u.user_id)
    order by
      pretty_name"

   set users_eval {} 
}

# Select subgroups, users
query subgroups multirow $groups_query
query users multirow $users_query -eval $users_eval

set return_url [ns_conn url]