<?xml version="1.0"?>
<queryset>

<fullquery name="insert_images">      
      <querytext>
      
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )
      </querytext>
</fullquery>

 
</queryset>
