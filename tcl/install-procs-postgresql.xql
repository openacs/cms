<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="cms::install::package_install.create_role">
      <querytext>
	        select acs_rel_type__create_role(:role,:pn,:pp)
      </querytext>
</fullquery>

</queryset>