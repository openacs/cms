<master src="../../master">
<property name="title">Template Folder - @folder_info.label;noquote@</property>

<p/>

<include src="/packages/cms/lib/clip" mount_point="@mount_point@" id="@folder_id@">

Template Folder - @folder_info.label;noquote@

<p/>

&nbsp;&nbsp;&nbsp;
<if @folder_info.description@ not nil>@folder_info.description;noquote@</if>
<else>No description</else>

<p/>

<include src="/packages/cms/lib/ancestors" item_id="@folder_id@" mount_point="@mount_point@">

<p/>

<include src="/packages/cms/lib/folder-items" 
	folder_id="@folder_id@"
	parent_id="@parent_id@" 
	actions="@actions;noquote@" 
	orderby="@orderby@" 
	page="@page@" 
	mount_point="@mount_point@" />

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>