ad_library {
    Workflow proc
}

namespace eval cms::workflow {}
namespace eval cms::workflow::get_authors {}
namespace eval cms::workflow::get_editors {}
namespace eval cms::workflow::get_publishers {}
namespace eval cms::workflow::set_publish_status {}

ad_proc -public cms::workflow::object_type {} {
    Return object type
} {
    return "content_revision"
}

ad_proc -public cms::workflow::create {} {
    Create a basic workflow for content
} {

    set spec {
        content {
            pretty_name "Content"
            package_key "cms"
            object_type "content_revision"
            roles {
                author {
                    pretty_name "Author"
                }
		editor {
		    pretty_name "Editor"
                    callbacks {
			cms.GetEditors
                        workflow.Role_PickList_CurrentAssignees
                    }
		}
                publisher {
                    pretty_name "Publisher"
                    callbacks {
			cms.GetPublishers
                        workflow.Role_PickList_CurrentAssignees
                    }
                }
            }
            states {
		initiated {
		    pretty_name "Initiated"
		}
                authored {
                    pretty_name "Authored"
                }
                edited {
                    pretty_name "Edited"
                }
		ready {
		    pretty_name "Ready"
		}
		live {
		    pretty_name "Live"
		}
		expired {
		    pretty_name "Expired"
		}

            }
            actions {
		initiate {
		    pretty_name "Initiate"
		    pretty_past_tense "Initiated"
                    new_state "initiated"
                    enabled_states { live expired }

		}
                author {
                    pretty_name "Author"
                    pretty_past_tense "Authored"
                    new_state "authored"
		    callbacks { cms.SetPublishStatus }
                }
                edit {
                    pretty_name "Edit"
                    pretty_past_tense "Edited"
                    new_state "edited"
                    assigned_role "editor"
                    allowed_roles { publisher }
                    assigned_states { authored }
                    privileges { write }
                }
                publish {
                    pretty_name "Publish"
                    pretty_past_tense "Published"
                    new_state "ready"
		    callbacks { cms.SetPublishStatus }
                    assigned_role "publisher"
                    assigned_states { edited }
                    enabled_states { authored }
                    privileges { write }
                }
                reject {
                    pretty_name "Reject"
                    pretty_past_tense "Rejected"
                    new_state "authored"
		    callbacks { cms.SetPublishStatus }
                    assigned_role "publisher"
                    assigned_states { edited }
                    enabled_states { authored ready live }
                    privileges { write }
                }
                comment {
                    pretty_name "Comment"
                    pretty_past_tense "Commented"
                    privileges { read write }
                    always_enabled_p t
                }
            }
        }
    }
    
    set workflow_id [workflow::fsm::new_from_spec -spec $spec]
    
    return $workflow_id


}

ad_proc -public cms::workflow::workflow_short_name {} {
    Get the short name of the workflow for content
} {
    return "content"
}

ad_proc -public cms::workflow::get_package_workflow_id {} { 
    Return the workflow_id for the package (not instance) workflow
} {
    return [workflow::get_id \
		-short_name [workflow_short_name] \
		-package_key [cms::package_key]]

}

ad_proc -public cms::workflow::get_instance_workflow_id {
    {-package_id {}}
} { 
    Return the workflow_id for the instance (not package) workflow
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    return [workflow::get_id \
		-short_name [workflow_short_name] \
		-object_id $package_id]
}

ad_proc -private cms::workflow::instance_workflow_create {
    {-package_id:required}
} {
    Creates a clone of the default bug-tracker package workflow for a
    specific package instance 
} {
    set workflow_id [workflow::fsm::clone \
			 -workflow_id [get_package_workflow_id] \
			 -object_id $package_id]
    
    return $workflow_id
}

ad_proc -private cms::workflow::instance_workflow_delete {
    {-package_id:required}
} {
    Deletes the instance workflow
} {
    workflow::delete -workflow_id [get_instance_workflow_id -package_id $package_id]
}

#####
#
# GetAuthors
#
#####

ad_proc -private cms::workflow::get_authors::pretty_name {} {
    return "GetAuthors"
}


ad_proc -private cms::workflow::get_authors::get_assignees {} {
    case_id
    object_id
    action_id
    entry_id
} {
    set app_group [application_group::group_id_from_package_id \
		       -package_id [ad_conn package_id]]
    return [db_list get_authors {}]
}

#####
#
# GetEditors
#
#####

ad_proc -private cms::workflow::get_editors::pretty_name {} {
    return "GetEditors"
}


ad_proc -private cms::workflow::get_editors::get_assignees {} {
    case_id
    object_id
    action_id
    entry_id
} {
    set app_group [application_group::group_id_from_package_id \
		       -package_id [ad_conn package_id]]
    return [db_list get_editors {}]
}

#####
#
# GetPublishers
#
#####

ad_proc -private cms::workflow::get_publishers::pretty_name {} {
    return "GetAuthors"
}


ad_proc -private cms::workflow::get_publishers::get_assignees {} {
    case_id
    object_id
    action_id
    entry_id
} {
    set app_group [application_group::group_id_from_package_id \
		       -package_id [ad_conn package_id]]
    return [db_list get_publishers {}]
}

#####
#
# SetPublishStatus
#
#####

ad_proc -private cms::workflow::set_publish_status::pretty_name {} {
    return "SetPublishStatus"
}


ad_proc -private cms::workflow::set_publish_status::set_status {} {
    case_id
    object_id
    action_id
    entry_id
} {
    workflow::case::fsm::get -case_id $case_id -array case_info
    content::item::update -item_id $object_id -attributes \
	[list publish_status $case_info(state_short_name)]
}

