# template ID is passed to included template

query live_revision onevalue "
  select live_revision from cr_items where item_id = :template_id"

# first count all revisions

set query "
  select
    count(*) 
  from 
    cr_revisions
  where
    item_id = :template_id"

query revision_count onevalue $query

set counter $revision_count

set query "
  select
    revision_id,
    to_char(o.creation_date, 'MM/DD/YY HH:MI AM') modified,
    round(dbms_lob.getlength(r.content) / 1000) || ' KB' as file_size,
    decode(NVL(p.person_id, 0),
        0, '-',
        substr(p.first_names, 1, 1) || substr(p.last_name, 1, 1)) modified_by,
    nvl(j.msg, '-') msg
  from 
    cr_revisions r, acs_objects o, persons p, journal_entries j
  where
    item_id = :template_id
  and
    o.object_id = r.revision_id
  and
    o.creation_user = p.person_id (+)
  and
    o.object_id = j.journal_id (+)
  order by
    o.creation_date desc"


query revisions multirow $query -maxrows 12 -eval {
  set row(revision_number) $counter
  incr counter -1
}