# /templates/template-create.tcl 
# create a content_template

request create
request set_param parent_id -datatype integer -optional

# Cannot use -value due to negative values
if { [template::util::is_nil parent_id] } {
  set parent_id [cm::modules::templates::getRootFolderID]
}

query folder_name onevalue "
  select name from cr_items where item_id = :parent_id"

if { [util::is_nil folder_name] } {
    set folder_name "/"
}


set page_title "Add a Template to $folder_name"


# Create a new item and an initial revision for a content item (generic)
form create create_template -elements {
    template_id -datatype integer -widget hidden
    parent_id -datatype integer -widget hidden -param -optional
    name -datatype keyword -widget text -label "File Name"
}

set parent_id [element get_value create_template parent_id]

if { [form is_request create_template] } {

    # to avoid dupe submits
    query template_id onevalue "select acs_object_id_seq.nextval from dual"
    element set_properties create_template template_id -value $template_id
}


if { [form is_valid create_template] } {

    form get_values create_template name parent_id template_id
    set user_id [User::getID]
    set ip_address [ns_conn peeraddr]
    
    if { [util::is_nil parent_id] } {
      set parent_id [cm::modules::templates::getRootFolderID]
    }
 

    set db [template::begin_db_transaction]

    ns_ora exec_plsql_bind $db "begin 
        :ret_val := content_template.new(
            template_id   => :template_id,
            name          => :name,
            parent_id     => :parent_id,
            creation_user => :user_id,
            creation_ip   => :ip_address
        );
        end;" ret_val

    template::end_db_transaction
    template::release_db_handle

    template::forward ../templates/template?template_id=$template_id
}

