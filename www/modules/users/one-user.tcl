request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param parent_id -datatype keyword -optional

set passthrough "mount_point=$mount_point&parent_id=$parent_id"

# Find basic user params
template::query get_info info onerow "
  select
    p.first_names, p.last_name, 
    pp.email, pp.url, 
    u.screen_name,
    to_char(u.last_visit, 'YYYY/MM/DD HH24:MI') as last_visit,
    to_char(u.no_alerts_until, 'YYYY/MM/DD') as no_alerts_until
  from
    persons p, parties pp, users u
  where
    p.person_id = :id
  and
    pp.party_id = :id
  and
    u.user_id = :id
"

# Find the groups to which this user belongs
template::query get_groups groups multirow "
  select 
    g.group_name, g.group_id
  from
    groups g, group_member_map m
  where
    m.group_id = g.group_id
  and
    m.member_id = :id
"
    
