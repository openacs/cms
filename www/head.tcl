# Get the name for the current user

set user_id [User::getID]

ns_log Notice $user_id

template::query name onevalue "
  select first_names || ' ' || last_name 
    from persons where person_id = :user_id"



