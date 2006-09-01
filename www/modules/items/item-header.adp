<nobr>
<p>
<include src="/packages/cms/lib/clip" mount_point="@mount_point@" id="@item_id@">@page_title;noquote@

</p>
</nobr>
<p/>

&nbsp;&nbsp;&nbsp;
<if @content_item.description@ not nil>@content_item.description;noquote@</if>
<else>No description</else>

<p/>

<include src="/packages/cms/lib/ancestors" item_id=@item_id@>

<p/>
