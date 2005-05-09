<master src="../../master">
<property name="title">Upload new template revision</property>

<script language=JavaScript>
  function setSrc(name, src) {
    document.images[name].src = "assets/" + src;
  }
</script>

<h3>Upload Template</h3>
@path@

<br/>
<formtemplate id="edit_template">
<formwidget id=template_id>
<formwidget id=revision_id>
<formwidget id=content>
<br/>

<input type=submit name=action value="Upload">
<input type=submit name=action value="Cancel">

</formtemplate>
