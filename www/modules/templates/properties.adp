<master src="../../master">
<property name="title">@page_title@</property>

<nobr><p class="h1">
<include src="../../bookmark" mount_point="@mount_point@" id="@item_id@">
@page_title;noquote@ 
</p>
</nobr>
<p/>

&nbsp;&nbsp;&nbsp;
<if @description@ not nil>@description;noquote@</if>
<else>No description</else>

<p/>

<include src="../sitemap/ancestors" mount_point=@mount_point@ item_id=@item_id@>

<p/>

<!-- Tabs -->

<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @template_props_tab@ eq general>
   <div class="tab" id="subnavbar-here">
     General
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&template_props_tab=general" title="" class="subnavbar-unselected">General</a>
   </div>
 </else>

 <if @template_props_tab@ eq revisions>
   <div class="tab" id="subnavbar-here">
     Revisions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&template_props_tab=revisions" title="" class="subnavbar-unselected">Revisions</a>
   </div>
 </else>

 <if @template_props_tab@ eq datasources>
   <div class="tab" id="subnavbar-here">
     Datasources
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&template_props_tab=datasources" title="" class="subnavbar-unselected">Datasources</a>
   </div>
 </else>

 <if @template_props_tab@ eq assets>
   <div class="tab" id="subnavbar-here">
     Assets
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&template_props_tab=assets" title="" class="subnavbar-unselected">Assets</a>
   </div>
 </else>

 <if @template_props_tab@ eq types>
   <div class="tab" id="subnavbar-here">
     Content Types
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&template_props_tab=types" title="" class="subnavbar-unselected">Content Types</a>
   </div>
 </else>

 <if @template_props_tab@ eq items>
   <div class="tab" id="subnavbar-here">
     Content Items
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&template_props_tab=items" title="" class="subnavbar-unselected">Content Items</a>
   </div>
 </else>

  </div>
 </div>
</div>

<div id="subnavbar-body">

<div id=section>
<include src=@template_props_tab@ template_id=@item_id@>
</div>

</div>