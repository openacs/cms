<nobr><p>
<include src="/packages/cms/lib/clip" mount_point="@mount_point@" id="@item_id@">
Content Template - @template_info.title;noquote@
</p>
</nobr>
<p/>

&nbsp;&nbsp;&nbsp;
<if @template_info.description@ not nil>@template_info.description;noquote@</if>
<else>No description</else>

<p/>

<include src="/packages/cms/lib/ancestors" mount_point=@mount_point@ item_id=@item_id@>

<p/>
