<master src="../../master">
<property name="title">@page_title@</property>

<include src="template-header" mount_point=@mount_point@ item_id=@item_id@ &=tab>

<include src="template-tabs" mount_point=@mount_point@ item_id=@item_id@ &=tab>

<div id="subnavbar-body">

 <div id=section>
  <if @tab@ eq revisions>
   <include src="/packages/cms/lib/revisions" item_id=@item_id@ mount_point=@mount_point@ content_method="">
  </if>
  <elseif @tab@ eq permissions>
   <div id=section-header>Template permissions</div>
    <include src="/packages/acs-subsite/www/permissions/perm-include" object_id="@item_id@">
   </div>
  </elseif>
  <else>
   <include src=@tab@ template_id=@item_id@ &=tab revision_id=@revision_id@>
  </else>
 </div>

 <p>

 <if @write_p@>
  <a href="@revise_url@" class="button">Author Revision</a>
  <a href="@rename_url@" class="button">Rename Template</a>
  <a href="@delete_url@" class="button" 
     onClick="return confirm('Warning! You are about to delete this template: @template_info.title@.');">
     Delete Template</a>
  <a href="@upload_url@" class="button">Upload Revision</a>
  <a href="@download_url@" class="button">Download Revision</a>
 </if>

</div>