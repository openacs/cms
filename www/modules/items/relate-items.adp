<master src="../../master">
<property name="title">@page_title;noquote@</property>

<include src="item-header" item_id="@item_id@" mount_point="sitemap">

<include src="item-tabs" item_id="@item_id@" tab="related">

<div id="subnavbar-body">

 <div id=section>
  <div id=section-header>@page_title@</div>
   <p></p>

   <if @target_items:rowcount@ gt 0>
    <form action="relate-items-2" method="post">
    <table class="list" cellpadding="3" cellspacing="1">
      <tr class="list-header">
       <th class="list" align="left"></td>
       <th class="list" align="left">Title</td>
       <th class="list" align="left">Type</td>
       <th class="list" align="left">Tag</td>
       <th class="list" align="left">Order</td>
      </tr>
     <multiple name=target_items>
      <tr class="<if @target_items.rownum@ even>list-even</if><else>list-odd</else><if @target_items.rownum@ eq @target_items:rowcount@> last</if>">
       <input type="hidden" name="target_item_id.@target_items.rownum@" value="@target_items.item_id@">
       <input type="hidden" name="target_items" value="@target_items.rownum@">
       <td class="list" align="left"><input name="relate_p.@target_items.rownum@" type="checkbox"></td>
       <td class="list" align="left">@target_items.title;noquote@</td>
       <td class="list" align="left">@target_items.type_options;noquote@</td>
       <td class="list" align="left">@target_items.tag_options;noquote@</td>
       <td class="list" align="left"><input name="order_n.@target_items.rownum@" type="text" size="1"></td>
      </tr>
    </multiple>
    <input type="hidden" name="item_id" value="@item_id@">
    </table>
    <p>
    <input type="submit" value="Relate Checked Items">
    </form>
   </if>

 </div>

</div>
