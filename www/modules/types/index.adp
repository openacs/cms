<master src="../../master">
<property name="title">@page_title;noquote@</property>

<if @refresh_tree@ eq t>
  <script language=javascript>
    top.treeFrame.setCurrentFolder('@mount_point@', '@refresh_id@', '@parent_id@');
  </script> 
</if>

<nobr><p class="h1">
<include src="../../bookmark" mount_point="@mount_point@" id="@id@">
@page_title;noquote@ 
</p>
</nobr>
<p/>

<font size=-1>
 <strong>Inheritance: </strong>&nbsp;
   <if @content_type_tree:rowcount@ eq 1>
    Basic item
   </if>
   <else>
    <multiple name=content_type_tree>
      <if @content_type_tree.object_type@ eq @content_type@>
        @content_type_tree.pretty_name;noquote@
      </if>
          
      <else>
        <a href="index?id=@content_type_tree.object_type@&mount_point=types&parent_id=@content_type_tree.parent_type@">
          @content_type_tree.pretty_name;noquote@
        </a>
      </else> 
      <if @content_type_tree.rownum@ lt @content_type_tree:rowcount@> : </if>
    </multiple>
   </else>

</font>

<!-- Set up tabs -->

<div id="subnavbar-div">
  <div id="subnavbar-container">
    <div id="subnavbar">

 <if @type_props_tab@ eq attributes>
   <div class="tab" id="subnavbar-here">
     Attributes
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/types/index?id=@id@&mount_point=@mount_point@&parent_id=@parent_id@&type_props_tab=attributes" title="" class="subnavbar-unselected">Attributes</a>
   </div>
 </else>

 <if @type_props_tab@ eq relations>
   <div class="tab" id="subnavbar-here">
     Relations
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/types/index?id=@id@&mount_point=@mount_point@&parent_id=@parent_id@&type_props_tab=relations" title="" class="subnavbar-unselected">Relations</a>
   </div>
 </else>

 <if @type_props_tab@ eq templates>
   <div class="tab" id="subnavbar-here">
     Templates
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/types/index?id=@id@&mount_point=@mount_point@&parent_id=@parent_id@&type_props_tab=templates" title="" class="subnavbar-unselected">Templates</a>
   </div>
 </else>

 <if @type_props_tab@ eq permissions>
   <div class="tab" id="subnavbar-here">
     Permissions
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/types/index?id=@id@&mount_point=@mount_point@&parent_id=@parent_id@&type_props_tab=permissions" title="" class="subnavbar-unselected">Permissions</a>
   </div>
 </else>

 <if @type_props_tab@ eq subtypes>
   <div class="tab" id="subnavbar-here">
     Subtypes
   </div>
 </if>
 <else>
   <div class="tab">
     <a href="@package_url@modules/types/index?id=@id@&mount_point=@mount_point@&parent_id=@parent_id@&type_props_tab=subtypes" title="" class="subnavbar-unselected">Subtypes</a>
   </div>
 </else>

  </div>
 </div>
</div>

<div id="subnavbar-body">

  <if @type_props_tab@ eq attributes>

    <div id=section>
    <include src="attributes" can_edit_widgets="@can_edit_widgets@" content_type="@content_type@">
    </div>
    <p/>

    <div id=section>
    <include src="mime-types" content_type="@content_type@">
    </div>
    <p/>

    <div id=section>
    <include src="content-method" content_type="@content_type@">
    </div>

 </if>

 <if @type_props_tab@ eq relations>

    <include src="relations" content_type=@content_type;noquote@>

 </if>

<if @type_props_tab@ eq templates>

    <div id=section>    
    <div id=section-header>Registered Templates</div>
    <p/>
    <listtemplate name="type_templates"></listtemplate>
    </div>

</if>

<if @type_props_tab@ eq permissions>

    <div id=section>    
    <include src="../permissions/index" 
      object_id=@module_id;noquote@ 
      mount_point="types" 
      return_url="@return_url;noquote@" 
      passthrough="@passthrough;noquote@">
    </div>

</if>

<if @type_props_tab@ eq subtypes>
    
    <div id=section>
    <include src="subtypes" content_type=@content_type;noquote@ object_type_pretty=@object_type_pretty;noquote@>
    </div>

</if>

<br>

</div>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>
