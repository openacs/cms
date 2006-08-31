<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="cms::install::package_install.create_role">
      <querytext>
	        select acs_rel_type.create_role(:role,:pn,:pp)
      </querytext>
</fullquery>

</queryset>