# @namespace workflow

# Procedures for applying workflow to an item in CMS

namespace eval workflow {}

# @public notify_of_assignments

# Emails assigned users of new publishing workflow tasks

# @author Michael Pih

# @param db A database handle
# @param case_id The publishing workflow
# @param user_id The From: user when sending the email

proc workflow::notify_of_assignments { db case_id user_id } {

    template::query assignments multilist "
      select
        transition_name, party_id, 
        content_item.get_title(i.item_id) title,
        to_char(cd.deadline,'Month DD, YYYY') deadline_pretty,
        nvl(party.name(party_id),person.name(party_id)) name
      from
        wf_transitions t, cr_items i,
        wf_cases c, wf_case_assignments ca, wf_case_deadlines cd
      where
        c.workflow_key = 'publishing_wf'
      and
        c.workflow_key = t.workflow_key
      and
        ca.transition_key = t.transition_key
      and
        ca.transition_key = cd.transition_key
      and
        c.case_id = ca.case_id
      and
        c.case_id = cd.case_id
      and
        c.case_id = :case_id
      and
        c.state = 'active'
      and
        c.object_id = i.item_id
    " -db $db

    
    foreach assignment $assignments {
	set transition_name [lindex $assignment 0]
	set party_id        [lindex $assignment 1]
	set title           [lindex $assignment 2]
	set deadline_pretty [lindex $assignment 3]
	set name            [lindex $assignment 4]

	set subject \
		"You Have Been Assigned A Task: $transition_name of $title"
	set message "
Dear $name,
    You have been assigned a task: $transition_name of $title.
This task is due on $deadline_pretty.
"

	ns_ora exec_plsql_bind $db "
	  begin
	  :request_id := nt.post_request(
	      party_from   => :user_id,
	      party_to     => :party_id,
	      expand_group => 'f',
	      subject      => :subject,
	      message      => :message
	  );
          end;
        " request_id
    }

}



# @public notify_admin_of_new_tasks

# Sends email notification to the creator of an item who has been assigned
#   to a specific task (author/edit/approve that item)

# @author Michael Pih

# @param db A database handle
# @param case_id The workflow of an item
# @param transition_key The name of the task

proc workflow::notify_admin_of_new_tasks { db case_id transition_key } {

    template::query assignments multilist "
      select
        o.creation_user as admin_id, transition_name, party_id, 
        content_item.get_title(i.item_id) title,
        to_char(deadline,'Month DD, YYYY') deadline_pretty,
        nvl(party.name(party_id),person.name(party_id)) name,
        nvl(party.name(admin_id),person.name(admin_id)) admin_name
      from
        wf_cases c, wf_case_assignments ca, wf_case_deadlines cd,
        wf_transitions t, cr_items i, acs_objects o
      where
        c.workflow_key = 'publishing_wf'
      and
        c.workflow_key = t.workflow_key
      and
        c.case_id = ca.case_id
      and
        c.case_id = cd.case_id
      and
        c.case_id = :case_id
      and
        ca.transition_key = t.transition_key
      and
        ca.transition_key = cd.transition_key
      and
        t.transition_key = :transition_key
      and
        c.state = 'active'
      and
        c.object_id = i.item_id
      and
        c.case_id = o.object_id
    " -db $db

    foreach assignment $assignments {
	set admin_id        [lindex $assignment 0]
	set transition_name [lindex $assignment 1]
	set party_id        [lindex $assignment 2]
	set title           [lindex $assignment 3]
	set deadline_pretty [lindex $assignment 4]
	set name            [lindex $assignment 5]
	set admin_name      [lindex $assignment 6]

	set subject \
		"$name Has Been Assigned A Task: $transition_name of $title"
	set message "
Dear $admin_name,
    $name has been assigned a task: $transition_name of $title.
This task is due on $deadline_pretty.
"

	ns_ora exec_plsql_bind $db "
	  begin
	  request_id := nt.post_request(
	      party_from   => -1,
	      party_to     => :admin_id,
	      expand_group => 'f',
	      subject      => :subject,
	      message      => :message
	  );
          end;
        " request_id
    }

}



# @public notify_admin_of_finished_tasks

# Notify that the admin of when a workflow task has been completed

# @author Michael Pih

# @param db A database handle
# @param task_id The task

proc workflow::notify_admin_of_finished_task { db task_id } {

    # the user who finished the task
    set user_id [User::getID]
    template::query name onevalue "
      select person.name( :user_id ) from dual
    " -db $db

    # get the task name, the creation_user, title, and date of the item
    template::query task_info onerow "
      select
        transition_name, 
        content_item.get_title(i.item_id) as title,
        o.creation_user as admin_id,
        person.name( o.creation_user ) as admin_name,
        to_char(sysdate,'Mon DD, YYYY') as today
      from
        wf_tasks t, wf_transitions tr, wf_cases c,
        cr_items i, acs_objects o
      where
        tr.transition_key = t.transition_key
      and
        tr.workflow_key = t.workflow_key
      and
        t.case_id = c.case_id
      and
        c.object_id = i.item_id
      and
        i.item_id = o.object_id
      and
        t.task_id = :task_id
    " -db $db

    template::util::array_to_vars task_info


    set subject \
	    "Task Finished: $transition_name of $title"

    set message "Dear $admin_name,
    $name has completed the task: $transition_name of $title on $today."

    ns_ora exec_plsql_bind $db "
      begin
      :request_id := nt.post_request(
          party_from   => -1,
	  party_to     => :admin_id,
	  expand_group => 'f',
	  subject      => :subject,
	  message      => :message
      );
      end;
    " request_id
}




# @public check_wf_permission

# A permission check that Integrates user permissions with workflow tasks

# @author Michael Pih

# @param db A database handle
# @param item_id The item on which to check permissions
# @param show_error t Flag indicating whether to display an error message
#                     or return t

# @return Redirects to an error page if show_error is t. If show_error is f,
# then returns t if the current user has permission to access the item, f 
# if not

proc workflow::check_wf_permission { db item_id {show_error t}} {

    set user_id [User::getID]

    template::query can_touch onevalue "
      select
        content_workflow.can_touch( :item_id, :user_id )
      from
        dual
    " -db $db

    if { [string equal $can_touch t] } {
	return t
    } else {
        if { [string equal $show_error t] } {
	  content::show_error "You cannot access this item at this time" \
		  "index"
	}
	return f
    }
}



# @private mail_notifications

# Schedules procedure for mailing notifications

# @author Michael Pih

proc workflow::mail_notifications {} {
    ns_log Notice "Running Scheduled Notifications Proc"

    set mail_server [template::util::get_param mail_server "ns/server/[ns_info server]/cms" OutgoingMailServer]
    set mail_port [template::util::get_param mail_port "ns/server/[ns_info server]/cms" MailPort]

    # if there's no mail server, don't run scheduled processes
    if { [template::util::is_nil mail_server] } {
	return
    }

    # default mail port, if none is set
    if { [template::util::is_nil mail_port] } {
	set mail_port 25
    }
	
    set db [template::begin_db_transaction]

    template::query process_queue dml "
      begin
        nt.process_queue( :mail_server, :mail_port );
      end;
    "

    template::end_db_transaction
}

ns_schedule_proc -thread 300 workflow::mail_notifications
