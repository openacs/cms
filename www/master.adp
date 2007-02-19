<master>
<property name="title">@title@</property>

<style>
div#section {
  border: 1px dotted;
  padding: 10px;
}

div#section-header {
  background-color: #888888;
  color: white;
  font: bold;
  padding-left: 10px;
}
</style>

<script language=Javascript src="@clipboard_js@"></script>

<p/>

<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @section@ eq "sitemap">
  <div class="tab" id="subnavbar-here">
    Content
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/sitemap/index" title="">Content</a>
  </div>
 </else>

 <if @section@ eq "templates">
    <div class="tab" id="subnavbar-here">
    Templates
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/templates/index" title="">Templates</a>
  </div>
 </else>

 <if @section@ eq "types">
  <div class="tab" id="subnavbar-here">
    Types
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/types/index" title="">Types</a>
  </div>
 </else>

 <if @section@ eq "sw-categories">
  <div class="tab" id="subnavbar-here">
    Categories
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/sw-categories/index" title="">Categories</a>
  </div>
 </else>

 <if @section@ eq "keywords">
  <div class="tab" id="subnavbar-here">
    Keywords
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/categories/index" title="">Keywords</a>
  </div>
 </else>

 <if @section@ eq "search">
  <div class="tab" id="subnavbar-here">
    Search
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/search/index" title="">Search</a>
  </div>
 </else>

 <if @section@ eq "clipboard">
  <div class="tab" id="subnavbar-here">
    Clipboard
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/clipboard/index" title="">Clipboard</a>
    <!--[<a href="javascript: void(openrefreshClipboard('@package_url@modules/clipboard/floating?mount_point=clipboard','clipboard','toolbar=no,innerWidth=500,innerHeight=300,scrollbars=yes'))" title="Open floating clipboard">float</a>]-->
  </div>
 </else>

 <if @section@ eq "admin">
  <div class="tab" id="subnavbar-here">
    Admin
  </div>
 </if>
 <else>
  <div class="tab">
    <a href="@package_url@modules/admin/index" title="">Admin</a>
  </div>
 </else>

   </div>
 </div>
</div>

<slave>

