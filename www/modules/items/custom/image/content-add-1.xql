<?xml version="1.0"?>
<queryset>

<fullquery name="update_images">      
      <querytext>
      
      update images
        set width = :width,
        height = :height
        where image_id = :revision_id
      </querytext>
</fullquery>

 
</queryset>
