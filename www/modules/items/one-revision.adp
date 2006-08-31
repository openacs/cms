<if @content_method@ ne no_content>
 <div id=section-header>Content</div>
  <p/>
   <if @content_method@ eq text_entry>@content;noquote@</if>
   <else>
    <if @file_type@ eq image>
      <img src="@download_url@">
    </if>
    <else>
      Content is a file of type @mime_type@. <a href="@download_url@">Download</a>.
    </else>
   </else>
</if>