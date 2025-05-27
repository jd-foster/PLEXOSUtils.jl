
# PLEXOS version setting:
const PLEXOS_VERSION = @load_preference("plexos_version", 9)

const TYPES_DEF_FILE = @load_preference("types_def_file", joinpath("v$(PLEXOS_VERSION)","types.jl"))
const TABLE_DEF_FILE = @load_preference("table_def_file", joinpath("v$(PLEXOS_VERSION)","tables.jl"))

# Table types to ignore by default when parsing the PLEXOS XML:
const IGNORED_TABLES = @load_preference("ignored_tables", ["t_band", "t_data", "t_tag"])
# Usage: customise which table types are ignored (e.g. "t_a", "t_b") by setting 
#   set_ignored_tables([ "t_a", "t_b"])
# before restarting and calling exported functions from this module.

function set_plexos_version(new_version::VersionNumber)
    if !(new_version.major in (9, 10, 11))
        throw(ArgumentError("Unsupported PLEXOS version: \"$(new_version)\""))
    end

    # Set it in our runtime values, as well as saving it to disk
    @set_preferences!("plexos_version" => new_version)
    @info("New PLEXOS version set to $(new_version); restart your Julia session for this change to take effect.")
end

set_plexos_version(new_version) = set_plexos_version(VersionNumber(new_version))
get_plexos_version() = @load_preference("plexos_version", PLEXOS_VERSION)

# A non-compiletime preference
function set_ignored_tables(ignored_tables::Vector{String})
    @set_preferences!("ignored_tables" => ignored_tables)
    @info("Ignored tables are now $(ignored_tables);
           you may need restart your Julia session for this change to take effect.")
end
function get_ignored_tables()
    return @load_preference("ignored_tables", IGNORED_TABLES)
end