<master src="../../master">
<property name="title">@page_title@</property>

<p/>

<include src="../../bookmark" mount_point="@mount_point@" id="@parent_id@">

@page_title;noquote@ 

<p/>

&nbsp;&nbsp;&nbsp;
<if @info.description@ not nil>@info.description@</if>
<else>No description</else>

<p/>

<include src="../sitemap/ancestors" item_id=@parent_id@ mount_point=@mount_point@>

<p/>

<listtemplate name="folder_contents"></listtemplate>

<script language=JavaScript>set_marks('templates', 'assets/checked');</script>
