module PLEXOSUtils

import Base.==
import Dates: DateTime
import EzXML: EzXML, Document, eachelement, namespace, Node, nodecontent, parsexml
import libzip_jll: libzip
import OrderedCollections: OrderedDict
import Preferences: Preferences, @load_preference, @set_preferences!

export open_plexoszip, PLEXOSSolutionDataset, PLEXOSSolutionDatasetSummary

include("user_settings.jl")
include(@load_preference("types_def_file", TYPES_DEF_FILE))
include(@load_preference("table_def_file", TABLE_DEF_FILE))

include("index.jl")
include("PLEXOSSolutionDatasetSummary.jl")
include("PLEXOSSolutionDataset.jl")
include("libzip.jl")
include("utils.jl")

end
