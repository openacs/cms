<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="cms::template::add_revision.add_revision">
		<querytext>
			select content_revision__new(:title, :description, current_timestamp, :mime_type, null, :content, :template_id, null, current_timestamp, :creation_user, :creation_ip)
		</querytext>
</fullquery>

</queryset>