ad_page_contract {

    @author Michael Steigman (michael@steigman.net)
    @creation-date October 2004
} {
    {module "modules/workspace/index"}
}

set user_id [auth::require_login]

ns_returnredirect $module