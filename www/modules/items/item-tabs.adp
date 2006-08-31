<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @tab@ eq item>
   <div class="tab" id="subnavbar-here">
     Item
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=item" title="" class="subnavbar-unselected">Item</a>
   </div>
 </else>

 <if @tab@ eq revisions>
   <div class="tab" id="subnavbar-here">
     Revisions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=revisions" title="" class="subnavbar-unselected">Revisions</a>
   </div>
 </else>

 <if @tab@ eq related>
   <div class="tab" id="subnavbar-here">
     Related
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=related" title="" class="subnavbar-unselected">Related</a>
   </div>
 </else>

 <if @tab@ eq categories>
   <div class="tab" id="subnavbar-here">
     Categories
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=categories" title="" class="subnavbar-unselected">Categories</a>
   </div>
 </else>

 <if @tab@ eq templates>
   <div class="tab" id="subnavbar-here">
     Templates
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=templates" title="" class="subnavbar-unselected">Templates</a>
   </div>
 </else>

 <if @tab@ eq publishing>
   <div class="tab" id="subnavbar-here">
     Publishing
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=publishing" title="" class="subnavbar-unselected">Publishing</a>
   </div>
 </else>

 <if @tab@ eq permissions>
   <div class="tab" id="subnavbar-here">
     Permissions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=sitemap&tab=permissions" title="" class="subnavbar-unselected">Permissions</a>
   </div>
 </else>

  </div>
 </div>
</div>

