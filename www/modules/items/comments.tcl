# List comments about an item (or add a new comment)

request create -params {
  item_id -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}

# Check permissions
content::check_access $item_id cm_read \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# The creation_user may be null, in which case 'System' is substituted

set query "
  select
    journal_id, action_pretty, msg, 
    decode(NVL(p.person_id, 0),
        0, 'System',
        substr(p.first_names, 1, 1) || '. ' || p.last_name) person,
    to_char(o.creation_date, 'MM/DD/YY HH24:MI:SS') when
  from
    journal_entries j, acs_objects o, persons p
  where
  (   
      j.object_id = :item_id
    or
      j.object_id in (select case_id from wf_cases c 
                      where c.object_id = :item_id)
  ) and
    j.journal_id = o.object_id
  and
    o.creation_user = p.person_id (+)
  and
    msg is not null
  order by
    o.creation_date desc
"

template::query comments multirow $query -maxrows 10
