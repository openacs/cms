<?xml version="1.0"?>
<queryset>

<fullquery name="cms::install::package_install.role_exists">
      <querytext>
	        select r.pretty_name from acs_rel_roles r where r.role=:role
      </querytext>
</fullquery>

<fullquery name="cms::install::package_instantiate.update_group_rels">
      <querytext>
	insert into group_rels
	(group_rel_id, group_id, rel_type)
	values
	(acs_object_id_seq.nextval,:app_group,:rel);
      </querytext>
</fullquery>

<fullquery name="cms::install::package_instantiate.map_subsite">
      <querytext>
	insert into cms_subsite_package_map
        (subsite_id,package_id)
        values
        (:subsite_package,:package_id)
      </querytext>
</fullquery>
 
</queryset>
