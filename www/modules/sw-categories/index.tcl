ad_page_contract {

} {
    { orderby "title,asc" }
    { page:optional ""}
    { category_id:optional }
    { mount_point "items" }
}

set content_root [cm::modules::sitemap::getRootFolderID [ad_conn subsite_id]]
set package_id [ad_conn package_id]

set categories [list]
set trees [category_tree::get_mapped_trees $package_id]
foreach tree $trees {
    set tree [lindex $tree 0]
    foreach category [category_tree::get_tree $tree] {
	set pad ""
	if { [lindex $category 3] > 1 } {
	    set pad [string repeat "." [lindex $category 3]]
	}
	lappend categories [list "$pad[lindex $category 1]" [lindex $category 0]]
    }
}

template::list::create \
    -name categorized_items \
    -multirow categorized_items \
    -actions [list "Manage Categories" \
		  "/categories/cadmin/one-object?object_id=$package_id" \
		  "Manage site wide categories for this package"] \
    -has_checkboxes \
    -key item_id \
    -page_size 25 \
    -page_query {
	select i.item_id, content_item__get_title(i.item_id,'f') as title, category__name(com.category_id,'en_US') as category
          from cr_items i join category_object_map com on (i.item_id = com.object_id) 
               join acs_object_types t on (i.content_type = t.object_type)
               [list::filter_where_clauses -and -name categorized_items]
               [list::orderby_clause -name categorized_items -orderby]
    } \
    -page_flush_p 1 \
    -elements {
	title {
	    label "Title"
	    link_html { title "@categorized_items.full_title@"}
	    link_url_col item_url
	    orderby title
	}
	pretty_name {
	    label "Content Type"
	    orderby pretty_name
	}
	category {
	    label "Category"
	    orderby category
	}
    } \
    -filters {
	category_id {
	    label "Categories"
	    values { $categories }
	    where_clause {
		category_id = :category_id
	    }
	}
    }

db_multirow -extend { item_url copy full_title } categorized_items get_categorized_items "
    select i.item_id, content_item__get_title(i.item_id,'f') as title, 
           r.revision_id, i.parent_id, t.pretty_name,
           category__name(com.category_id,'en_US') as category, i.content_type
      from cr_items i join category_object_map com on (i.item_id = com.object_id) 
           join cr_revisions r on (r.revision_id = content_item__get_best_revision(i.item_id))
           join acs_object_types t on (i.content_type = t.object_type)
           [list::page_where_clause -and -name categorized_items -key i.item_id]
           [list::filter_where_clauses -and -name categorized_items]
           [list::orderby_clause -name categorized_items -orderby]
" {
    set item_url [export_vars -base ../items/index { item_id parent_id mount_point }]
    set full_title $title
    set title [string_truncate -len 30 $title]
}
