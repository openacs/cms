<listtemplate name="related"></listtemplate>

<p>

<if @related_types_registered_p@>
 <formtemplate id=add_related_item>
  Add a new related item
  <formwidget id=parent_id><formwidget id=content_type> 
  <input type=submit value="Add">
  </formtemplate>
</if>

