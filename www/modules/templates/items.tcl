template::list::create \
    -name content_items \
    -multirow content_items \
    -elements {
	title {
	    label "Content Item"
	    link_url_col item_url
	}
	use_context {
	    label "Use Context"
	}
    }

db_multirow  -extend { item_url } content_items get_content_items {} {
    set item_url [export_vars -base ../items/index { item_id }]
} 
