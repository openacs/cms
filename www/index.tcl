# Get the name for the current user

set user_id [User::getID]

if { ! $user_id } { template::forward "signin" }

template::query get_name name onevalue "
  select 
    first_names || ' ' || last_name 
  from 
    persons 
  where 
    person_id = :user_id
"


ns_set put [ns_conn outputheaders] Pragma "No-cache"
