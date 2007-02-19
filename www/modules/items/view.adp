<html>
<head>
 <title>Item Viewer</title>
</head>
<body>
<link rel="stylesheet" href="/definitions.css" type="text/css">
<table>
 <tr>
   <th style="padding: 5px 5px 5px 5px; border-bottom: 1px solid #dddddd; background-color: #cccccc;">Field</th>
   <th style="padding: 5px 5px 5px 5px; border-bottom: 1px solid #dddddd;">Value</th>
 </tr>
 <multiple name=attributes>
  <tr>
    <td style="padding: 5px 5px 5px 5px; border-bottom: 1px solid #dddddd; background-color: #cccccc;">@attributes.attribute@</td>
    <td style="padding: 5px 5px 5px 5px; border-bottom: 1px solid #dddddd;">@attributes.value;noquote@ &nbsp;</td>
  </tr>
 </multiple>

<if @content_p@>
 <tr>
  <td style="padding: 5px 5px 5px 5px; border-bottom: 1px solid #dddddd; background-color: #cccccc;">content</td>
  <td  style="padding: 5px 5px 5px 5px; border-bottom: 1px solid #dddddd;">
   <if @content_method@ eq text_entry>@content;noquote@</if>
   <else>
    <if @file_type@ eq image>
      <img src="@download_url@">
    </if>
    <else>
      Content is a file of type @mime_type@. <a href="@download_url@">Download</a>.
    </else>
   </else>
 </td></tr>
</if>
</table>
</body>
</html>
