<?xml version="1.0"?>
<queryset>

<fullquery name="publish::set_publish_status.sps_update_cr_items">      
      <querytext>
      update cr_items set publish_status = :new_status
                              where item_id = :item_id
      </querytext>
</fullquery>

<fullquery name="publish::schedule_status_sweep.package_id">      
      <querytext>
	select package_id from apm_packages where package_key = 'cms'
      </querytext>
</fullquery>
 
</queryset>
