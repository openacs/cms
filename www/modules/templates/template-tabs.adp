<!-- Tabs -->

<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

<!-- <if @tab@ eq template>
   <div class="tab" id="subnavbar-here">
     Template
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=template" title="" class="subnavbar-unselected">Template</a>
   </div>
 </else>
-->
 <if @tab@ eq revisions>
   <div class="tab" id="subnavbar-here">
     Revisions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=revisions" title="" class="subnavbar-unselected">Revisions</a>
   </div>
 </else>

 <if @tab@ eq datasources>
   <div class="tab" id="subnavbar-here">
     Datasources
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=datasources" title="" class="subnavbar-unselected">Datasources</a>
   </div>
 </else>

 <if @tab@ eq assets>
   <div class="tab" id="subnavbar-here">
     Assets
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=assets" title="" class="subnavbar-unselected">Assets</a>
   </div>
 </else>

 <if @tab@ eq types>
   <div class="tab" id="subnavbar-here">
     Content Types
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=types" title="" class="subnavbar-unselected">Content Types</a>
   </div>
 </else>

 <if @tab@ eq items>
   <div class="tab" id="subnavbar-here">
     Content Items
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=items" title="" class="subnavbar-unselected">Content Items</a>
   </div>
 </else>

 <if @tab@ eq permissions>
   <div class="tab" id="subnavbar-here">
     Permissions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/templates/properties?item_id=@item_id@&mount_point=@mount_point@&tab=permissions" title="" class="subnavbar-unselected">Permissions</a>
   </div>
 </else>

  </div>
 </div>
</div>
