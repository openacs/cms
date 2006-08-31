<master src="../../master">
<property name="title">@page_title@</property>
<property name="mount_point">@mount_point@</property>

<nobr><p>
<include src="/packages/cms/lib/clip" mount_point="@mount_point@" id="@folder_id@">
@page_title;noquote@ 
</p>
</nobr>
<p/>

&nbsp;&nbsp;&nbsp;
<if @folder_info.description@ not nil>@folder_info.description@</if>
<else>No description</else>

<p/>

<span style="font-size: 80%;">Back to <a href="../@mount_point@/index?folder_id=@folder_id@&mount_point=@mount_point@">@folder_info.label@</a></span>

<!-- Tabs -->

<include src="folder-tabs" &=folder_props_tab &=folder_id &=mount_point>

<!-- Content -->

<div id="subnavbar-body">

<if @folder_props_tab@ eq registered>
  <div id=section>
  <div id=section-header>Content types registered to the folder</div>
  <p/>
  <listtemplate name="content_types"></listtemplate>
  </div>
</if>

<if @folder_props_tab@ eq special>
  <div id=section>
  <div id=section-header>Folder options for special types</div>
  <p/>
  <formtemplate id="special_types"></formtemplate>
  </div>
</if>

<if @folder_props_tab@ eq permissions>
  <div id=section>
  <div id=section-header>Folder permissions</div>
  <include src="/packages/acs-subsite/www/permissions/perm-include" object_id="@folder_id@">
  </div>
</if>

</div>