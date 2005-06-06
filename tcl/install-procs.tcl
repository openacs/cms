ad_library {
    install callbacks
}

namespace eval cms::install {}

ad_proc -public cms::install::package_instantiate { -package_id } {
    Procedures to run on package instantiation
} {
    # create modules for new instance
    cm::modules::install::create_modules -package_id $package_id

    set subsite_dir "/www"
    append subsite_dir [site_node::get_url_from_object_id -object_id [ad_conn subsite_id]]
    # check that directory exists and...
    if { ![file exists $subsite_dir] } {
	file mkdir $subsite_dir
    }

    # copy content delivery .vuh file to subsite root
    file copy -force /packages/cms/www/index.vuh $subsite_dir
    
}

ad_proc -public cms::install::package_uninstantiate { -package_id } {
    Procedures to run on package uninstantiation
} {
    cm::modules::install::delete_modules -package_id $package_id
}
