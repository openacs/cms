<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @folder_props_tab@ eq registered>
   <div class="tab" id="subnavbar-here">
     Registered Types
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@url@&folder_props_tab=registered" title="" class="subnavbar-unselected">Registered Types</a>
   </div>
 </else>

 <if @folder_props_tab@ eq special>
   <div class="tab" id="subnavbar-here">
     Special Types
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@url@&folder_props_tab=special" title="" class="subnavbar-unselected">Special Types</a>
   </div>
 </else>

 <if @folder_props_tab@ eq permissions>
   <div class="tab" id="subnavbar-here">
     Permissions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@url@&folder_props_tab=permissions" title="" class="subnavbar-unselected">Permissions</a>
   </div>
 </else>

  </div>
 </div>
</div>

