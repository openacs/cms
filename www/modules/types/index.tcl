# ad_page_contract {

#     @author Michael Steigman (michael@steigman.net)
#     @creation-date October 2004
# } {
#     {id "content_revision"}
#     {mount_pount "types"}
#     {parent_id ""}
#     {type_props_tab "attributes"}
# }

# query for attributes of this subclass of content_revision and display them

request create
request set_param id -datatype keyword -value content_revision
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -value types
request set_param type_props_tab -datatype keyword -value attributes
request set_param refresh_tree -datatype keyword -optional -value t

set package_url [ad_conn package_url]

# Tree hack
if { [string equal $id content_revision] } {
  set refresh_id ""
} else {
  set refresh_id $id
}

set content_type $id
set user_id [auth::require_login]
set root_id [cm::modules::templates::getRootFolderID]

set module_id [db_string get_module_id ""]

content::check_access $module_id cm_examine -user_id $user_id

set can_edit_widgets $user_permissions(cm_write)


# get the content type pretty name
set object_type_pretty [db_string get_object_type ""]

if { [string equal $object_type_pretty ""] } {
    # error - invalid content_type
    template::forward index
}


# get all the content types that this content type inherits from
db_multirow content_type_tree get_content_type ""

template::list::create \
    -name type_templates \
    -multirow type_templates \
    -has_checkboxes \
    -no_data "There are no templates registered to this content type." \
    -actions [list "Register marked templates to this content type" [export_vars -base register-templates {content_type}] "Register marked templates to this content type"] \
    -elements {
        name {
	    label "Template Name"
	}
	path {
	    label "Path"
	}
	pretty_name {
	    label "Content Type"
	}
	use_context {
	    label "Context"
	}
	is_default {
	    label "Default?"
	    display_template "<if @type_templates.is_default@ eq t>Yes</if><else><a href=\"@type_templates.set_default_url@\">set as default</a></else>"
	}
	unreg_link {
	    display_template "<center><a href=\"@type_templates.unreg_link_url;noquote@\">unregister</a></center>"
	}
	
    }

# get template information
db_multirow -extend {unreg_link unreg_link_url set_default_url} type_templates get_type_templates "" {
    set context $use_context
    set unreg_link_url [export_vars -base unregister-template {template_id context content_type}]
    set set_default_url [export_vars -base set-default-template {template_id context content_type}]
}

set page_title "Content Type - $object_type_pretty"

# for the permissions include
set return_url [ns_conn url]
set passthrough [content::assemble_passthrough return_url mount_point id]

# for templates table
if { [string equal $user_permissions(cm_write) t] } {
    set footer "<a href=\"register-templates?content_type=$content_type\">
    Register marked templates to this content type</a>"
} else {
    set footer ""
}

# Create the tabbed dialog
set url [ad_conn url]
append url "?id=$id&mount_point=$mount_point&parent_id=$parent_id&refresh_tree=f"

# template::tabstrip create type_props -base_url $url
# template::tabstrip add_tab type_props attributes "Attributes and Uploads" attributes
# template::tabstrip add_tab type_props relations "Relation Types" relations
# template::tabstrip add_tab type_props templates "Templates" templates
# template::tabstrip add_tab type_props permissions "Permissions" permissions

