<master src="../../master">
<property name="title">@page_title@</property>

<include src="item-header" item_id="@item_id@" mount_point="sitemap">

<!-- Tabs -->

<include src="item-tabs" &=tab &=item_id>

<! -- Content -->

<div id="subnavbar-body">

<if @tab@ eq item>

  <div id=section>
   <include src="attributes" revision_id="@revision_id@">
  </div>
  <p>

  <include-optional src="one-revision" &=revision_id &=content_method &=item_id>
    <div id=section> 
     <include-output>
    </div>
  </include-optional>

</if>

<if @tab@ eq revisions>

  <div id=section>
   <include src="/packages/cms/lib/revisions" item_id="@item_id@" content_method="@content_method@" mount_point=@mount_point@>
  </div>
  <p>

</if>

<if @tab@ eq related>

  <div id=section>
   <div id=section-header>Related Items</div>
   <p/>
    <include src="related-items" item_id="@item_id;noquote@">
  </div>
  <p>

  <div id=section>
   <div id=section-header>Child Items</div>
   <p/>
    <include src="children" item_id="@item_id;noquote@">
  </div>
  <p>

</if>

<if @tab@ eq categories>

  <div id=section>
   <include src="keywords" item_id="@item_id;noquote@" mount_point="@mount_point;noquote@">  
  </div>

</if>

<if @tab@ eq publishing>

  <div id=section>
   <div id=section-header>Publishing Status</div>
   <p/>
    <include src="publish-status" item_id="@item_id;noquote@">
  </div>
  <p>

</if>

<if @tab@ eq templates>
  <div id=section>
   <div id=section-header>Registered Templates</div>
   <p/>
    <include src="templates" item_id="@item_id@">
  </div>
  <p>

</if>
  <!-- <div id=section>
   <div id=section-header>Comments</div>
   <p/>
    Place holder for comments
  </div> -->
  <p>

</if>

<if @tab@ eq permissions>
  
  <div id=section>
  <div id=section-header>Item permissions</div>
   <include src="/packages/acs-subsite/www/permissions/perm-include" object_id="@item_id@">
  </div>
  <p/>

</if>

<!-- Options at the end -->

<p>

<if @preview_p@>
  <a href="@preview_url@" target="_new" class="button">Preview</a>
</if>

<if @write_p@>
  <a href="@revise_url@" class="button">@revise_button@</a>
  <a href="@rename_url@" class="button">Rename</a> 
  <a href="@delete_url@" class="button" 
     onClick="return confirm('Warning! You are about to delete this @content_item.content_type@: @content_item.title@.');">
     Delete</a>
</if>

</div>

<p>
