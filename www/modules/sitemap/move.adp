<master src="../../master">
<property name="title">Move Items to @path@</property>
<h2>Move Items to @path@</h2>


<if @no_items_on_clipboard@ eq "t">
  <p>No items are currently available for linking. Please mark
     your choices and return to this form.</p>
</if>
<else>
<formtemplate id="move">
<formwidget id="id">

<p>  
  <formerror id=moved_items>
    <font color=red>Please choose at least one item to move</font>
  </formerror>
</p>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width=95%>

<tr>
<td>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width=100%>

  <tr><td>&nbsp;</td>
      <th align=left>Name</th>
      <th align=left>Title</th>

  <multiple name=marked_items>

  <if @marked_items.rownum@ odd><tr bgcolor=white></if>
  <else><tr bgcolor=#eeeeee></else>

  <td>
    <input name=moved_items type=checkbox value=@marked_items.item_id@>
    <formwidget id="parent_id_@marked_items.item_id@">
  </td>

  <td>
    @marked_items.name@
  </td>

  <td>
    @marked_items.title@
  </td>
   
  </tr>

  </multiple>

</table>

</td></tr>

</table>

<br>

<input type=submit value="Submit">

</formtemplate>
</else>