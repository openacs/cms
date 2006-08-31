
@message@

<p/>
<ul>
  <li>This item is <if @is_publishable@ eq f>not</if>
      in a publishable state. <if @is_publishable@ eq f>
      Related content may be required.</if></li>

  <!-- Revision status -->
  <if @live_revision@ nil>
    <li>This item has no live revision.</li>
  </if>

  <!-- child rel status -->
  <if @unpublishable_child_types@ gt 0>

   <li>This item requires the following number of child items:
     <ul>
      <multiple name="child_types">
        <if @child_types.is_fulfilled@ eq f>
         <li>@child_types.difference@ @child_types.direction@ 
             @child_types.relation_tag@ 
             <if @child_types.difference@ eq 1>@child_types.child_type_pretty@</if>
             <else>@child_types.child_type_plural@</else>
         </li>
        </if>
      </multiple>
     </ul>
   </li>
  </if>

  <!-- item rel status -->
  <if @unpublishable_rel_types@ gt 0>

   <li>This item requires the following number of related items:
    <ul>
      <multiple name="rel_types">
         <if @rel_types.is_fulfilled@ eq f>
          <li>@rel_types.difference@ @rel_types.direction@ 
              @rel_types.relation_tag@ 
              <if @rel_types.difference@ eq 1>@rel_types.target_type_pretty@</if>
              <else>@rel_types.target_type_plural@</else>
          </li>
         </if>
      </multiple>
     </ul>
    </li>
  </if>

</ul>

<p/>

<if @can_edit_status_p@>
 <ul class="action-links">
  <if @live_revision@ nil>
    <li><a href="publish?item_id=@item_id@&tab=@tab@&revision_id=@latest_revision@">Make latest revision live</a></li>
  </if>
  <li><a href="status-edit?item_id=@item_id@&tab=@tab@">Edit publishing status</a></li>
 </ul>
</if>

