<?xml version="1.0"?>
<queryset>

<fullquery name="cms::install::package_instantiate.map_subsite">
      <querytext>
	insert into cms_subsite_package_map
        (subsite_id,package_id)
        values
        (:subsite_id,:package_id)
      </querytext>
</fullquery>
 
</queryset>
