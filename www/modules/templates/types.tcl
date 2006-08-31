template::list::create \
    -name content_types \
    -multirow content_types \
    -elements {
	pretty_name {
	    label "Content Type"
	    link_url_col type_url
	}
	is_default {
	    label "Default?"
	}
    }

db_multirow  -extend { type_url } content_types get_content_types {} {
    set type_url [export_vars -base ../types/index { content_type }]
} 
