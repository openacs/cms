set clipboard [clipboard::parse_cookie]

set cookie [clipboard::parse_cookie]

set in_list [join [clipboard::get_items $cookie templates] ","]

set template_count [llength $in_list]

if { $template_count > 0 } {

  set query "select
    template_id, content_item.get_path(template_id) path
  from
    cr_templates
  where
    template_id in ($in_list)"

  query templates multirow $query
}

set return_url [ns_set iget [ns_conn headers] Referer]