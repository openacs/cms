request create

request set_param id -datatype integer -optional
request set_param parent_id -datatype integer -optional
request set_param mount_point -datatype keyword -optional -value users

form create edit_user

form section edit_user "User Parameters"

element create edit_user item_id \
  -label "Item ID" -datatype integer -widget hidden -value $id
element create edit_user user_id \
  -label "User ID" -datatype integer -widget hidden -value [User::getID] 
element create edit_user mount_point \
  -label "Mount Point" -datatype keyword -widget hidden -param -optional
element create edit_user parent_id \
  -label "Parent ID" -datatype keyword -widget hidden -param -optional
element create edit_user first_names \
  -label "First Names" -datatype text -widget text -html { size 30 }
element create edit_user last_name \
  -label "Last Name" -datatype text -widget text -html { size 30 }
element create edit_user screen_name \
  -label "Screen Name" -datatype text -widget text -html { size 20 }
element create edit_user email \
  -label "Email" -datatype text -widget text -optional -html { size 40 }
element create edit_user url \
  -label "URL" -datatype text -widget text -optional -html { size 40 }

form section edit_user "Alerts"

element create edit_user no_alerts_until \
  -label "No alerts until" -datatype date -widget date -optional \
  -format "DD/MONTH/YYYY" -year_interval { 2000 2010 1 } -help

form section edit_user "Change Password"

element create edit_user password \
  -label "New Password" -datatype text -widget password -optional \
  -html { size 20 }

element create edit_user password2 \
  -label "Re-type Password" -datatype text -widget password -optional \
  -html { size 20 } -validate {
    { string equal $value [template::element get_value edit_user password] } {
      Passwords do not match
    }
  } 

if { [form is_request edit_user] } {

  # Find basic user params
  template::query get_user_info info onerow "
    select
      p.first_names, p.last_name, 
      pp.email, pp.url, 
      u.screen_name,
      to_char(u.no_alerts_until, 'YYYY/MM/DD') as no_alerts_until
    from
      persons p, parties pp, users u
    where
      p.person_id = :id
    and
      pp.party_id = :id
    and
      u.user_id = :id
  "

  form set_values edit_user info
}

if { [form is_valid edit_user] } {

  form get_values edit_user first_names last_name screen_name item_id \
    user_id parent_id mount_point email url password no_alerts_until

  set users_update "set screen_name=:screen_name"
  if { [util::date get_property not_null $no_alerts_until] } {
    append users_update ", no_alerts_until=[util::date get_property sql_date $no_alerts_until]"
  }
  if { ![util::is_nil password] } {

    # hash the password

    set salt [ns_rand]
    set hashed_password [ns_sha1 "$password$salt"]

    append users_update ", password=:hashed_password, salt=:salt"
  }

  db_transaction {
      db_dml edit_user_1 "
    update users $users_update where user_id = :item_id
  "
      db_dml edit_user_2 "
    update persons set first_names=:first_names, last_name = :last_name 
      where person_id=:item_id
  "
      db_dml edit_user_3 "
    update parties set email=:email, url=:url where party_id = :item_id
  "
  }

  template::forward "one-user?id=$item_id&parent_id=$parent_id&mount_point=$mount_point"

}


  

 
