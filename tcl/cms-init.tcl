ad_library {

    Schedule a proc to keep track of the publish status. Resets
    the publish status to "expired" if the expiration date has passed.
    Publishes the item and sets the publish status to "live" if 
    the current status is "ready" and the scheduled publication time
    has passed.
     
    @creation-date 1 June 2005
    @author Michael Steigman (michael@steigman.net)
    @cvs-id $Id$
}
 
# Should be a CR parameter
set interval 120
ad_schedule_proc -thread t $interval publish::track_publish_status


