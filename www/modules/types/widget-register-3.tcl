# register a widget to an attribute

request create
request set_param attribute_id -datatype integer
request set_param widget -datatype keyword -optional

set step [wizard current_step]
set last_step [expr $step-1]
set back_url [wizard get_forward_url $last_step]

# no widget, no form
if { [template::util::is_nil widget] } {
    return
}


# the preview form
form create widget_preview
wizard submit widget_preview -buttons { back finish }

if { [form is_request widget_preview] } {

    template::query get_outstanding outstanding_params_list onelist "
      select
        distinct param
      from
        cm_form_widget_params f
      where
        is_required = 't'
      and
        widget = :widget
      and
        not exists (
          select 1
          from
            cm_attribute_widget_params
          where
            attribute_id = :attribute_id
          and
            param_id = f.param_id )
    "
 
    # the number of required widget params that are missing
    set outstanding_params [llength $outstanding_params_list]

    template::query get_names attribute_names onerow "
      select
        pretty_name, attribute_name, object_type
      from
        acs_attributes
      where
        attribute_id = :attribute_id
    "

    template::util::array_to_vars attribute_names
    content::add_attribute_element widget_preview $object_type $attribute_name
}

if { [form is_valid widget_preview] } {
    form get_values widget_preview
    wizard forward
}

