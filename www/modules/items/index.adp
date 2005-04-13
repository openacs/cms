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

<include src="../sitemap/ancestors" item_id=@item_id@>

<p/>

<!-- Tabs -->

<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @item_props_tab@ eq editing>
   <div class="tab" id="subnavbar-here">
     Editing
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=@mount_point@&item_props_tab=editing" title="" class="subnavbar-unselected">Editing</a>
   </div>
 </else>

 <if @item_props_tab@ eq children>
   <div class="tab" id="subnavbar-here">
     Children
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=@mount_point@&item_props_tab=children" title="" class="subnavbar-unselected">Children</a>
   </div>
 </else>

 <if @item_props_tab@ eq publishing>
   <div class="tab" id="subnavbar-here">
     Publishing
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=@mount_point@&item_props_tab=publishing" title="" class="subnavbar-unselected">Publishing</a>
   </div>
 </else>

 <if @item_props_tab@ eq permissions>
   <div class="tab" id="subnavbar-here">
     Permissions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/items/index?item_id=@item_id@&mount_point=@mount_point@&item_props_tab=permissions" title="" class="subnavbar-unselected">Permissions</a>
   </div>
 </else>

  </div>
 </div>
</div>

<div id="subnavbar-body">

<if @item_props_tab@ eq editing>

  <div id=section>
  <include src="attributes" revision_id="@info.latest_revision;noquote@">
  </div>
  <p>

  <div id=section>
  <include src="revisions" item_id="@item_id;noquote@" page="@page;noquote@">
  </div>
  <p>

  <div id=section>
  <include src="keywords" item_id="@item_id;noquote@" mount_point="@mount_point;noquote@">  
  </div>

</if>

<if @item_props_tab@ eq children>

  <div id=section>
   <div id=section-header>Child Items</div>
   <p/>
   <include src="children" item_id="@item_id;noquote@">
  </div>
  <p>

  <div id=section>
   <div id=section-header>Related Items</div>
   <p/>
   <include src="related-items" item_id="@item_id;noquote@">
  </div>
  <p>

</if>

<if @item_props_tab@ eq publishing>

  <div id=section>
   <div id=section-header>Publishing Status</div>
   <p/>
   <include src="publish-status" item_id="@item_id;noquote@">
  </div>
  <p>

  <div id=section>
   <div id=section-header>Registered Templates</div>
   <p/>
   <include src="templates" item_id="@item_id;noquote@">
  </div>
  <p>

  <div id=section>
   <div id=section-header>Comments</div>
   <p/>
   Place holder for comments
  </div>
  <p>

</if>

<if @item_props_tab@ eq permissions>
  
  <div id=section>
  <div id=section-header>Item permissions</div>
  <include src="/packages/acs-subsite/www/permissions/perm-include" object_id="@item_id@">
  </div>
  <p/>

</if>

<!-- Options at the end -->

<if @can_edit_p@>
  <p>
  <a href="rename?item_id=@item_id@&mount_point=@mount_point@">
    Rename</a> this content item
</if>
<if @can_edit_p@>
  <br>
  <a href="delete?item_id=@item_id@&mount_point=@mount_point@" 
     onClick="return confirm('Warning! You are about to delete this content item.');">
     Delete</a> this content item
  <p>
</if>

</div>

<p>
