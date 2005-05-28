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


<table>
<tr><td>

<table>
<tr>
      <th>Name</th><td>&nbsp;&nbsp;</td>
      <th>Type</th><td>&nbsp;&nbsp;</td>
      <th>Description and multirow/form details</th><td>&nbsp;&nbsp;</td>
</tr>  

<multiple name="datasources">
  <tr>
    <td align=left valign=top>@datasources.name@</td><td>&nbsp;</td>
    <td align=left valign=top>@datasources.structure@</td><td>&nbsp;</td>
    <td align=left valign=top>@datasources.comment@
     <if @datasources.structure@ in multirow multilist form>
      <p/>
       <table class="list" cellpadding=3 cellspacing=1>
        <if @datasources.structure@ in multirow multilist>
         <tr class="list-header">
	   <th class="list">Column</th><th class="list">Comment</th>
         </tr>
	 <group column="name">
           <if @datasources.rownum@ "odd"><tr class="list-odd"></if><else><tr class="list-even"></else>
	    <td class="list">@datasources.column_name@</td>
            <td class="list">@datasources.column_comment@</td>
	   </tr>
	 </group>
        </if>
	<else>
	 <tr class="list-header">
	    <th class="list">Name</th>
            <th class="list">Type</th>
	    <th class="list">Comment</th>
	 </tr>
	 <group column="name">
           <if @datasources.rownum@ "odd"><tr class="list-odd"></if><else><tr class="list-even"></else>
            <td class="list">@datasources.input_name@</td>
            <td class="list">@datasources.input_type@</td>
            <td class="list">@datasources.input_comment@</td>
           </tr>
	 </group>
	</else>
      </table>
     </if>
   </td>
  </tr>
</multiple>

</table>

</td></tr>
</table>
</else>
</else>
</else>
