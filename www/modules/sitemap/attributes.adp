<master src="../../master">
<property name="title">@page_title@</property>

<nobr><p class="h1">
<include src="../../bookmark" mount_point="@mount_point@" id="@folder_id@">
@page_title;noquote@ 
</p>
</nobr>
<p/>

<!-- MS: HACK -->
<if @call_ancestors_p@>
 <include src="ancestors" item_id=@folder_id@ mount_point=@mount_point@> : <a href="index?item_id=@folder_id@&mount_point=@mount_point@">@folder_name@</a>
</if>
<else>
 <font size="-1"><strong>Path:</strong>&nbsp;&nbsp;<a href="index?item_id=@folder_id@&mount_point=@mount_point@">@folder_name@</a></font>
</else>

<p/>

<div id=section>
<div id=section-header>Content types registered to the folder</div>
<p/>
<listtemplate name="content_types"></listtemplate>
</div>

<p/>

<div id=section>
<div id=section-header>Folder options for special types</div>
<p/>
<formtemplate id="special_types"></formtemplate>
</div>

<p/>

<div id=section>
<include src="../permissions/index" object_id="@folder_id;noquote@" 
  mount_point="@mount_point;noquote@" return_url="@return_url;noquote@" passthrough="@passthrough;noquote@">
</div>
