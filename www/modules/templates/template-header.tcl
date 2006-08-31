request create -params {
    item_id -datatype integer
    mount_point -datatype keyword -optional -value templates
    template_props_tab -datatype keyword -optional -value revisions
}

cms::template::get -template_id $item_id
