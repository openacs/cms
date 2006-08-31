<master src="../../master">
<property name="title">Clipboard</property>

<p/>

&nbsp;Clipboard

<p/>

&nbsp;&nbsp;&nbsp;Manage items on the clipboard

<p/>

<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @clip_tab@ eq main>
   <div class="tab" id="subnavbar-here">
     Main Menu
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/clipboard/index?mount_point=@mount_point@&clip_tab=main" title="" class="subnavbar-unselected">Main Menu</a>
   </div>
 </else>

 <if @clip_tab@ eq sitemap>
   <div class="tab" id="subnavbar-here">
     Content
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/clipboard/index?mount_point=@mount_point@&clip_tab=sitemap" title="" class="subnavbar-unselected">Content</a>
   </div>
 </else>

 <if @clip_tab@ eq templates>
   <div class="tab" id="subnavbar-here">
     Templates
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/clipboard/index?mount_point=@mount_point@&clip_tab=templates" title="" class="subnavbar-unselected">Templates</a>
   </div>
 </else>

 <if @clip_tab@ eq types>
   <div class="tab" id="subnavbar-here">
     Types
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/clipboard/index?mount_point=@mount_point@&clip_tab=types" title="" class="subnavbar-unselected">Types</a>
   </div>
 </else>

 <if @clip_tab@ eq search>
   <div class="tab" id="subnavbar-here">
     Search
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/clipboard/index?mount_point=@mount_point@&clip_tab=search" title="" class="subnavbar-unselected">Search</a>
   </div>
 </else>

 <if @clip_tab@ eq categories>
   <div class="tab" id="subnavbar-here">
     Keywords
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/clipboard/index?mount_point=@mount_point@&clip_tab=categories" title="" class="subnavbar-unselected">Keywords</a>
   </div>
 </else>

  </div>
 </div>
</div>

<div id="subnavbar-body">
<if @id@ nil>
 <div id="section">
  <div id="section-header">Clipboard Main Menu</div>
   <if @total_items@ gt 0>
    <p>There @total_items_string@ on the clipboard. You may select one of
    the mount points on the left to view a list of marked items for the
    mount point or <a href="clear-clipboard">clear the clipboard</a>.</p>
   </if>
   <else>
    <p>There are no items on the clipboard.</p>
   </else>
 </div>
</if>
<else>

 <div id="section">
  <div id="section-header">Marked Items</div>
   <listtemplate name="marked_items"></listtemplate>
  </div>
</else>

