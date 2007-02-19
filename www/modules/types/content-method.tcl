
request create
request set_param content_type -datatype text -value content_revision
request set_param type_props_tab -datatype text -value content_method
request set_param mount_point -datatype text -value types

# permissions check - user must have read on the types module
permission::require_permission -party_id [auth::require_login] \
    -object_id [cm::modules::get_module_id -module_name types -subsite_id [ad_conn subsite_id]] -privilege read

set return_url [export_vars -base index {content_type content_method type_props_tab}]

template::list::create \
    -name content_methods \
    -multirow content_methods \
    -has_checkboxes \
    -no_data "There are no content methods registered to this content type. By default, all content methods will be available to this content type." \
    -elements {
	content_method {
	    label "Content Method"
	}
	description {
	    label "Description"
	}
	pretty_is_default {
	    label "Is default?"
	}
	action_links {
	    display_template "@content_methods.action_links;noquote@"
	}
	
    }

# fetch the content methods registered to this content type
db_multirow -extend {pretty_is_default action_links} content_methods get_methods "" {
    set content_method_unset_default_url [export_vars -base content-method-unset-default {content_type return_url}]
    set content_method_set_default_url [export_vars -base content-method-set-default {content_type content_method return_url}]
    set content_method_unregister_url [export_vars -base content-method-unregister {content_type content_method return_url}]

    set action_links ""
    if {[string match $is_default "t"]} {
	set pretty_is_default "Yes"
	append action_links "<a href=\"$content_method_unset_default_url\" class=\"button\">Unset default</a> "
    } else {
    	set pretty_is_default "No"
	append action_links "<a href=\"$content_method_set_default_url\" class=\"button\">Set as default</a> "
    }

    append action_links " <a href=\"$content_method_unregister_url\" class=\"button\">Unregister</a>"

}

# text_entry content method filter
# don't show text entry if a text mime type is not registered to the item
set has_text_mime_type [db_string check_status ""]

if { $has_text_mime_type == 0 } {
    set text_entry_filter_sql "and content_method != 'text_entry'"
} else {
    set text_entry_filter_sql ""
}


# fetch the content methods not register to this content type
set unregistered_content_methods [db_list_of_lists get_unregistered_methods ""]

set unregistered_method_count [llength $unregistered_content_methods]

# form to register unregistered content methods to this content type
if { [llength $unregistered_content_methods] > 0 } {
    set form_p 1
    ad_form -name register -action content-method -form {
	
	{content_type:text(hidden)
	    {value $content_type}
	}
	{return_url:text(hidden)
	    {value $return_url}
	}
	{content_method:text(select)
	    {label "Register Content Method"}
	    {options $unregistered_content_methods}
	}
	
    } -on_submit {
	
	cms::type::add_content_method -content_type $content_type \
	    -content_method $content_method
	cms::type::flush_content_methods_cache $content_type
	ad_returnredirect [export_vars -base index { mount_point type_props_tab content_type return_url}]
	ad_script_abort
	
    }
} else {
    set form_p 0
}
