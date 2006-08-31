<nobr>
<p>
<include src="/packages/cms/lib/clip" mount_point="@mount_point@" id="@item_id@">@page_title;noquote@
<span style="font-size: 70%;">[<a href="@path@" target="_new">preview</a>]</span>
</p>
</nobr>
<p/>

&nbsp;&nbsp;&nbsp;
<if @content_item.description@ not nil>@content_item.description;noquote@</if>
<else>No description</else>

<p/>

<include src="/packages/cms/lib/ancestors" item_id=@item_id@>

<p/>
