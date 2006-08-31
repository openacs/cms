ad_library {
    CMS procs
}

namespace eval cms {}

ad_proc -public cms::package_key {} {
    return package_key string (move this)
} {
    return "cms"
}
