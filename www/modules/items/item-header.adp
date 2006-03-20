<nobr>
<p>
<include src="../../bookmark" mount_point="@mount_point@" id="@item_id@">
@page_title;noquote@ (<a href="@path@" target="_new">preview</a>)
</p>
</nobr>
<p/>

&nbsp;&nbsp;&nbsp;
<if @content_item.description@ not nil>@content_item.description;noquote@</if>
<else>No description</else>

<p/>

<include src="../sitemap/ancestors" item_id=@item_id@>

<p/>
