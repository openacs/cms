# Add content

request create
request set_param content_method -datatype keyword
request set_param revision_id -datatype integer

set db [template::get_db_handle]

template::query one_revision onerow "
  select
    item_id, title as name
  from
    cr_revisions
  where
    revision_id = :revision_id
"

template::util::array_to_vars one_revision

# permissions check - must have cm_write on the item
content::check_access $item_id cm_write -user_id [User::getID]

template::release_db_handle

# if we have an invalid revision_id, then redirect
if { [template::util::is_nil name] } {
    ns_log Notice "content-add-2.tcl: ERROR - BAD REVISION_ID - $revision_id"
    template::forward "../sitemap/index"
}

set page_title "Add Content to $name"

form create add_content -html { enctype "multipart/form-data" } -elements {
  revision_id -datatype integer -widget hidden -param
}

# add content element
content::add_content_element add_content $content_method

# Process the form
if { [form is_valid add_content] } {
    form get_values add_content revision_id

    content::add_content add_content $revision_id
	
    template::forward "revision?revision_id=$revision_id"
}

