
form create register_user -elements {
  user_id -datatype integer -widget hidden
  first_name -datatype text -widget text -html { size 30 } -label "First Name"
  last_name -datatype text -widget text -html { size 30 } -label "Last Name"
  email -datatype text -widget text -html { size 30 } -validate { \
    { template::util::is_unique parties email $value } \
    { The email <b>$value</b> is taken. } \
  } -label "E-Mail"
  screen_name -datatype text -widget text -html { size 20 } -validate { \
    { template::util::is_unique users screen_name $value } \
    { The screen name <b>$value</b> is taken.  Please try another one. } \
  } -label "Screen Name"
  password -datatype text -widget password -html { size 20 } -validate { \
    { string equal $value [ns_queryget password.confirm] } \
    { Passwords do not match. } \
  } -label "Password"
  password.confirm -datatype text -widget password -html { size 20 } \
    -label "Confirm Password"
}



if { [form is_request register_user] } {
    
    template::query get_user_id user_id onevalue "
      select acs_object_id_seq.nextval from dual
    "

    set cms_admin_exists [User::cms_admin_exists]

    if { $cms_admin_exists == 0 } {
	set is_admin t
    } else {
	set is_admin f
    }

    element set_properties register_user user_id -value $user_id
}


if { [form is_valid register_user] } {

    form get_values register_user user_id email first_name last_name \
	    password screen_name

    set db [template::begin_db_transaction]
    
    set user_id [ad_user_new $email $first_name $last_name $password \
	    "" "" "" "" "" $user_id]

    ns_ora dml $db "
      update users
        set screen_name = :screen_name
        where user_id = :user_id"

    # if there are no users with the 'cm_admin' privilege 
    #   (the CMS has never been used), then this user will be the admin
    set cms_admin_exists [User::cms_admin_exists $db]
    if { $cms_admin_exists == 0 } {
	set is_admin t
    } else {
	set is_admin f
    }

    # make admin - grant 'cm_admin' privileges for all content items
    #   and for content modules
    if { [string equal $is_admin t] } {
	ns_ora dml $db "
	declare
	  cursor c_item_cur is
	    select item_id from cr_items
	    connect by parent_id = prior item_id
	    start with parent_id = 0;
	
          cursor c_module_cur is
	    select module_id from cm_modules;

	begin
  
	  for item_row in c_item_cur loop 
	    acs_permission.grant_permission (
	        object_id  => item_row.item_id, 
	        grantee_id => :user_id, 
	        privilege  => 'cm_admin'
	    );
	  end loop;

	  for v_module in c_module_cur loop
	    acs_permission.grant_permission (
	        object_id  => v_module.module_id,
	        grantee_id => :user_id,
	        privilege  => 'cm_admin'
            );
	  end loop;

	end;
	"
    }

    User::login $db $user_id

    template::end_db_transaction

    template::forward index
}
