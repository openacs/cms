# register a widget to an attribute

request create
request set_param attribute_id -datatype integer


form create widget_register -elements {
    content_type_pretty -datatype text -widget inform -label "Content Type"
    attribute_name_pretty -datatype text -widget inform -label "Attribute"
    attribute_id -datatype integer -widget hidden -param
    content_type -datatype keyword -widget hidden
    attribute_name -datatype keyword -widget hidden
}



template::query get_form_widgets form_widgets multilist "
  select
    widget, widget
  from
    cm_form_widgets
"


element create widget_register widget \
	-datatype keyword \
	-widget select \
	-options $form_widgets \
	-label "Form Widget"

element create widget_register is_required \
	-datatype keyword \
	-widget radio \
	-label "Is Required?" \
	-options { {Yes t} {No f} }

wizard submit widget_register -buttons { next }




if { [form is_request widget_register] } {


    template::query get_attr_info attribute_info onerow "
      select
        a.pretty_name as attribute_name_pretty, 
        t.pretty_name as content_type_pretty,
        t.object_type as content_type,
        a.attribute_name
      from
        acs_attributes a, acs_object_types t
      where
        a.object_type = t.object_type
      and
        a.attribute_id = :attribute_id
    "

    template::query get_reg_widget register_widget onerow "
      select
        widget as registered_widget, is_required
      from
        cm_attribute_widgets
      where
        attribute_id = :attribute_id
    " 


    template::util::array_to_vars attribute_info
    element set_properties widget_register content_type_pretty \
	    -value $content_type_pretty
    element set_properties widget_register attribute_name_pretty \
	    -value $attribute_name_pretty
    element set_properties widget_register attribute_name \
	    -value $attribute_name
    element set_properties widget_register content_type \
	    -value $content_type

    template::util::array_to_vars register_widget
    if { ![template::util::is_nil registered_widget] } {
	element set_properties widget_register widget \
		-values $registered_widget
	element set_properties widget_register is_required \
		-values $is_required
    }
}





if { [form is_valid widget_register] } {

    form get_values widget_register \
	    widget is_required attribute_name content_type

    db_transaction {

        template::query check_registered already_registered  onevalue "
      select 1
      from
        cm_attribute_widgets
      where
        attribute_id = :attribute_id
      and
        widget = :widget
    " 

        # just update the is_required column if this widget is already registered
        #   this way we don't overwrite the existing attribute widget params
        if { ![template::util::is_nil already_registered] && \
                 $already_registered } {
            db_dml update_widgets "
	  update cm_attribute_widgets
            set is_required = decode(is_required,'t','f','t')
            where attribute_id = :attribute_id
            and widget = :widget"
        } else {

            # (re)register a widget to an attribute
            db_exec_plsql register_widget "
	  begin
	  cm_form_widget.register_attribute_widget(
              content_type   => :content_type,
              attribute_name => :attribute_name,
              widget         => :widget,
              is_required    => :is_required
          );
	  end;"
        }
    }
    
    wizard set_param widget $widget
    wizard forward
}
