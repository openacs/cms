ad_page_contract {
    List the contents of a folder under in the template repository
    Either a path or a folder ID may be passed to the page.

    @author Michael Steigman
    @creation-date October 2004
} {
    { item_id:integer ""}
    { mount_point:optional "templates"}
    { path:optional "" }
}

set package_url [ad_conn package_url]
set clipboardfloats_p [clipboard::floats_p]

# Tree hack
if { $item_id == [cm::modules::templates::getRootFolderID] } {
  set refresh_id ""
} else {
  set refresh_id $item_id
}

if { ! [string equal $path {}] } {

    set item_id [db_string get_id ""]

    if { [string equal $item_id {}] } {

        set msg "The requested folder <tt>$path</tt> does not exist."
        request error invalid_path $msg
    }
} else {

  if { [string equal $item_id {}] } {
      set item_id [db_string get_root_folder_id ""]
  }

  set path [db_string get_path ""]
}

# query for the content type and redirect if a folder
set type [db_string get_type ""]

if { [string equal $type content_template] } {
  template::forward properties?item_id=$item_id
}

db_1row get_info "" -column_array info

set page_title "Template Folder - $info(label)"

set folder_id $item_id
set parent_id $item_id

template::list::create \
    -name folder_contents \
    -multirow folder_contents \
    -has_checkboxes \
    -actions [list "New Template" [export_vars -base new-template?mount_point=templates {folder_id}] "Create a new template within this folder" \
		  "New Folder" [export_vars -base new-folder?mount_point=templates {parent_id}] "Create a new folder within this folder" \
		  "Move Items" [export_vars -base move?mount_point=sitemap {folder_id}] "Move folder" \
		  "Copy Items" [export_vars -base copy?mount_point=sitemap {folder_id}] "Copy folder" \
		  "Delete Items" [export_vars -base delete?mount_point=sitemap {folder_id}] "Delete folder"] \
    -elements {
	copy {
	    label "Clipboard"
	    display_template "<center>@folder_contents.copy;noquote@</center>"
	}
	name {
	    label "Name"
	    link_url_col item_url
	    link_html { title "View this item" }
	}
	file_size {
	    label "Size"
	}
	type {
	    label "Type"
	}
	modified {
	    label "Last Modified"
	}
	transact {
	    display_template "<if @folder_contents.is_folder@ ne 1><a href=\"@folder_contents.edit_url@\" title=\"Edit template\">edit</a> &nbsp; | &nbsp; \
                              <a href=\"@folder_contents.upload_url@\" title=\"Upload template\">upload</a></if>" 
	}
    }

db_multirow -extend { copy file_size is_folder template_id upload_url edit_url type item_url } -unclobber folder_contents get_folders "" {
    set copy [clipboard::render_bookmark templates $item_id $package_url]
    set is_folder 1
    set type "Template Folder"
    set item_url [export_vars -base index { item_id }]
}

db_multirow -append -extend { copy is_folder folder_id label upload_url edit_url type item_url } folder_contents get_items "" {
    set copy [clipboard::render_bookmark templates $item_id $package_url]
    set is_folder 0
    set type "Template"
    set item_url [export_vars -base properties { item_id }]
    set edit_url [export_vars -base edit { template_id }]
    set upload_url [export_vars -base upload { template_id }]
}
