<master src="../../master">
<property name="title">Edit Template</property>

<script language=JavaScript>
  function setSrc(name, src) {
    document.images[name].src = "assets/" + src;
  }
</script>

<h3>Edit Template</h3>
@path;noquote@
<br/>

<formtemplate id="edit_template">
<formwidget id=template_id>
<formwidget id=revision_id>
<formwidget id=content>

<br/>
Output Type: 
<formwidget id="mime_type">
<br/>
Create new revision: 
<formgroup id="is_update">
  @formgroup.widget;noquote@ @formgroup.label;noquote@
</formgroup>
<br/>
<input type=submit name=action value="Save">&nbsp;&nbsp;
<input type=submit name=action value="Cancel">

</formtemplate>
