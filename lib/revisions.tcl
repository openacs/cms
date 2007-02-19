set list_action delete
set template_id $item_id
set return_url [ad_return_url]

template::list::create \
    -name revisions \
    -multirow revisions \
    -key revision_id \
    -bulk_actions [list "Delete Revisions" \
		       ../items/revision-handler \
		       "Delete checked revisions"] \
    -bulk_action_export_vars { item_id mount_point list_action return_url } \
    -elements {
	revision_number {
	    label "\#"
	}
	title {
	    label "Title"
	    display_template { @revisions.title;noquote@ }
	}
	description {
	    label "Description"
	}
	pretty_date {
	    label "Modification Date"
	}
	author {
	    label "Author"
	}
	file_size {
	    label "Size"
	}
	status {
	    label "Status"
	}
	options {
	    display_template {
		<a href=\"@revisions.view_url;noquote@\" class=\"button\" title=\"View revision\" target=\"_new\">View</a>
		<a href=\"@revisions.revise_url;noquote@\" class=\"button\" title=\"Author new revision based on this revision\">Revise</a>
		<if @revisions.status@ eq "Live">
		<a href=\"@revisions.unpublish_url;noquote@\" class=\"button\" title=\"Unpublish item\">Unpublish</a>
		</if>
		<else>
		<a href=\"@revisions.publish_url;noquote@\" class=\"button\" title=\"Publish item\">Publish</a>
		</else>
	    }
	}
    }    

set live_revision [content::item::get_live_revision -item_id $item_id]
set content_type [content::item::get_content_type -item_id $item_id]
if { $content_type eq "content_template" } {
    set revise_url_base template-ae
} else {
    set revise_url_base revision-add-2
}

db_multirow -extend { 
    pretty_date 
    view_url 
    revise_url 
    publish_url 
    unpublish_url
    revision_number 
    file_size 
    status 
    author
    options
} revisions get_revisions {} {
    set title [string_truncate -len 30 $title]
    if {[template::util::is_nil description]} {
	set description "-"
    } else {
	set description [string_truncate -len 40 $description]
    }
    if { ![ template::util::is_nil content_length ] } {
	set file_size "[lc_numeric [expr $content_length / 1000.00] "%.2f"] Kb"
    } else {
	set file_size "-"
    }
    if { $revision_id == $live_revision } {
	set status "Live"
    }
    if { ![ template::util::is_nil author_id ] } {
	set author [person::name -person_id $author_id]
    } else {
	set author "-"
    }

    set revision_number [content::revision::get_number -revision_id $revision_id]
    set pretty_date [lc_time_fmt $publish_date "%q %X"]
    set revise_url [export_vars -base $revise_url_base {item_id template_id revision_id mount_point content_method return_url}]
    set publish_url [export_vars -base publish { item_id revision_id return_url }]
    set unpublish_url [export_vars -base unpublish { item_id return_url }]
    set list_action view
    set view_url [export_vars -base ../items/view {item_id revision_id mount_point list_action return_url}]

}

# sort by revision_number, not date
template::multirow sort revisions -decreasing -integer revision_number
