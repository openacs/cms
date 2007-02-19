ad_library {
    Install routines for CMS package
}

namespace eval cms::install {}

ad_proc -public cms::install::package_install {} {
    Procedures to run on package installation
} {

    db_transaction {
	# register callback implementations and create the basic workflow 
	cms::install::register_implementations
	set workflow_id [cms::workflow::create]
	ns_log debug "cms::install::package_install - workflow_id is $workflow_id"
	
	# add system roles for editors, authors and publishers
	# roles will be mapped to subsite rel segments on package instantiation
	#                     --Role--      --Pretty--    --Plural--
	set roles "    [list author        Author        Authors] \
                        [list editor        Editor        Editors] \
                        [list publisher     Publisher     Publishers]"
	
	foreach {role pn pp} $roles {
	    
	    # Base existence check on existing role
	    if { ![db_0or1row role_exists {}] } {
		db_1row new_role create_role {}
	    }
	}
    }
}

ad_proc -public cms::install::package_uninstall {} {
    Procedures to run on package uninstall (roles will remain in system)
} {
    cms::workflow::delete
    cms::install::unregister_implementations
}

ad_proc -public cms::install::before_instantiate {} {
    Check to be sure there isn't already a CMS instance under this subsite.
    not a callback but we need to check this somewhere below and bomb if nec.
} {

}

ad_proc -public cms::install::package_instantiate { -package_id } {
    Procedures to run on package instantiation
} {
    # create modules and clone workflow for new instance
    cm::modules::install::create_modules -package_id $package_id
#     cms::workflow::instance_workflow_create -package_id $package_id    

    # assumes we are mounting from the subsite
    array set subsite_info [site_node::get -node_id [ad_conn subsite_node_id]]
    set subsite_package $subsite_info(package_id)
    db_dml map_subsite {}

    set subsite_dir "[acs_root_dir]/www/$subsite_info(url)"
    # check that directory exists and...
#     if { ![file exists $subsite_dir] } {
# 	file mkdir $subsite_dir
#     }

    # copy content delivery .vuh file to subsite root
#    file copy -force [acs_root_dir]/packages/cms/www/index.vuh $subsite_dir

    # set up subsite segments for for workflow
    set app_group [application_group::group_id_from_package_id -package_id $subsite_package]

    set roles "    [list author        Author        Authors] \
                        [list editor        Editor        Editors] \
                        [list publisher     Publisher     Publishers]"
    set content_root [cm::modules::sitemap::getRootFolderID $subsite_package]
    set template_root [cm::modules::templates::getRootFolderID $subsite_package]

    foreach { role pn pp } $roles {
	# boy, this is really convoluted; we've (i??) gotta do better
	set rel [rel_types::new -supertype membership_rel -role_one "" -role_two $role ${role}_rel_${subsite_info(package_id)} \
		     "$subsite_info(instance_name) $pn" "$subsite_info(instance_name) $pp" group 0 0 person 0 0]
	rel_types::add_permissible application_group $rel
	# MS: move to tcl API with 5.2
	db_dml update_group_rels {}
	set segment [rel_segments_new $app_group $rel "$subsite_info(instance_name) $pp"]
	switch $role {
	    publisher {
		permission::grant -party_id $segment -object_id $content_root -privilege admin
		permission::grant -party_id $segment -object_id $template_root -privilege admin
	    }
	    default {
		permission::grant -party_id $segment -object_id $content_root -privilege read
		permission::grant -party_id $segment -object_id $template_root -privilege read
		permission::grant -party_id $segment -object_id $content_root -privilege create
		permission::grant -party_id $segment -object_id $template_root -privilege create
		permission::grant -party_id $segment -object_id $content_root -privilege write
		permission::grant -party_id $segment -object_id $template_root -privilege write
	    }
	}
    }

    # register template folder with dav module
    #set subsite_node site_node::get_node_id_from_object_id -object_id [ad_conn subsite_id]
    #set templates_node site_node::new -name templates -parent_id $subsite_node
    #oacs_dav::register_folder $templates_root $templates_node    
}

ad_proc -public cms::install::package_uninstantiate { -package_id:required } {
    Procedures to run on package uninstantiation
} {
    # unregister template folder
    #set subsite_url [site_node::get_url -node_id [site_node::get_node_id_from_object_id -object_id [ad_conn subsite_id]] -notrailing]
    #array set template_node [site_node::get_from_url -url ${subsite_url}/templates]
    #set template_root [cm::modules::templates::getRootFolderID $package_id $template_node(node_id)]
    #oacs_dav::unregister_folder $template_root node_id

    # delete modules and workflow
    cm::modules::install::delete_modules -package_id $package_id
    cms::workflow::instance_workflow_delete -package_id $package_id    

    # remove index.vuh
    set subsite_dir "[acs_root_dir]/www"
    append subsite_dir [site_node::get_url_from_object_id -object_id [ad_conn subsite_id]]
    file delete -force $subsite_dir/index.vuh
}


#####
#
# Service contract implementations
#
#####

ad_proc -private cms::install::register_implementations {} {
    db_transaction {
        cms::install::register_get_authors_impl
        cms::install::register_get_editors_impl
        cms::install::register_get_publishers_impl
        cms::install::register_set_publish_status_impl
    }
}

ad_proc -private cms::install::unregister_implementations {} {
    db_transaction {

        acs_sc::impl::delete \
	    -contract_name [workflow::service_contract::role_default_assignees] \
                -impl_name "GetAuthors"

        acs_sc::impl::delete \
	    -contract_name [workflow::service_contract::role_default_assignees] \
                -impl_name "GetEditors"

        acs_sc::impl::delete \
	    -contract_name [workflow::service_contract::role_default_assignees] \
                -impl_name "GetPublishers"

        acs_sc::impl::delete \
	    -contract_name [workflow::service_contract::action_side_effect] \
                -impl_name "SetPublishStatus"

    }
}

ad_proc -private cms::install::register_get_authors_impl {} {

    set spec {
        name "GetAuthors"
        aliases {
            GetObjectType cms::workflow::object_type
            GetPrettyName cms::workflow::get_authors::pretty_name
            GetAssignees  cms::workflow::get_authors::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees]
    lappend spec owner [cms::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private cms::install::register_get_editors_impl {} {

    set spec {
        name "GetEditors"
        aliases {
            GetObjectType cms::workflow::object_type
            GetPrettyName cms::workflow::get_editors::pretty_name
            GetAssignees  cms::workflow::get_editors::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees]
    lappend spec owner [cms::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private cms::install::register_get_publishers_impl {} {

    set spec {
        name "GetPublishers"
        aliases {
            GetObjectType cms::workflow::object_type
            GetPrettyName cms::workflow::get_publishers::pretty_name
            GetAssignees  cms::workflow::get_publishers::get_assignees
        }
    }
    
    lappend spec contract_name [workflow::service_contract::role_default_assignees]
    lappend spec owner [cms::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}

ad_proc -private cms::install::register_set_publish_status_impl {} {

    set spec {
        name "SetPublishStatus"
        aliases {
            GetObjectType cms::workflow::object_type
            GetPrettyName cms::workflow::set_publish_status::pretty_name
            DoSideEffect cms::workflow::set_publish_status::set_status
        }
    }
    
    lappend spec contract_name [workflow::service_contract::action_side_effect]
    lappend spec owner [cms::package_key]
    
    acs_sc::impl::new_from_spec -spec $spec
}


