<div id=section-header>Template Datasources</div>
<p/>

<if @template_exists@ eq f>
  This template does not exist.
</if>
<else>
<if @code_exists@ eq f or @file_exists@ eq f>
  The code for this template does not exist.
</if>
<else>
<if @datasources:rowcount@ eq 0>
  There are no known data sources in this template.
</if>
<else>


<table class="list" cellpadding=3 cellspacing=1>
<tr class="list-header">
      <th class="list">Name</th>
      <th class="list">Type</th>
      <th class="list">Description and multirow/form details</th>
</tr>  
<multiple name="datasources">
  <if @datasources.rownum@ "odd"><tr class="list-odd"></if><else><tr class="list-even"></else>
    <td align=left valign=top>@datasources.name@</td>
    <td align=left valign=top>@datasources.structure@</td>
    <td align=left valign=top>@datasources.comment@
     <if @datasources.structure@ in multirow multilist form>
        <if @datasources.structure@ in multirow multilist>
         <p/>Columns:
	 <group column="name">
	   <strong>@datasources.column_name@</strong>, @datasources.column_comment@;
	 </group>
        </if>
	<else>
         <p/>Fields:
	 <group column="name">
            <strong>@datasources.input_name@</strong>(@datasources.input_type@)
            <if @datasources.input_comment@ not nil>,</if>
            @datasources.input_comment@;
	 </group>
	</else>
     </if>
   </td>
  </tr>
</multiple>

</table>

</else>
</else>
</else>
