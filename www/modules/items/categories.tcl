request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -optional -value sitemap
request set_param tab -datatype keyword -optional -value categories

ad_form -name categories -action categories -form {
    {item_id:text(hidden) {value $item_id}}
} -on_submit {
    set form [ns_getform]
    set form_size [ns_set size $form]
    set form_counter_i 0
    set category_ids ""
    while {$form_counter_i < $form_size} {
	if { [string match "__category__ad_form__category_id_*" [ns_set key $form $form_counter_i]] } {
	    append category_ids "[ns_set value $form $form_counter_i] "
	}
	incr form_counter_i
    }
    category::map_object -remove_old -object_id $item_id $category_ids
    # MS: call below is not working for some reason (though the form data IS there)
    #[category::ad_form::get_categories -container_object_id [ad_conn package_id]]
} -after_submit {
    ad_returnredirect [export_vars -base . {item_id mount_point tab}]
    ad_script_abort
}


set form_p 1
if { [expr [llength [category_tree::get_mapped_trees [ad_conn package_id]]] > 0] } {
    category::ad_form::add_widgets \
	-container_object_id [ad_conn package_id] \
	-categorized_object_id $item_id \
	-form_name categories
    ad_form -extend -name categories -form {
	{submit:text(submit) {label "Update Categories"}}
    }
} else {
    set form_p 0
}
