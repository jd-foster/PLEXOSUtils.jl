
struct PLEXOSTable
    name::String
    fieldname::Symbol
    fieldtype::DataType
    loadorder::Int
    identifier::Union{String,Nothing}
    indexoffset::Int

    PLEXOSTable(
        name::String, fieldname::Symbol, fieldtype::DataType, loadorder::Int,
        identifier::Union{String,Nothing}=nothing,
        indexoffset::Int=0
    ) = new(name, fieldname, fieldtype, loadorder, identifier, indexoffset)
end

# Input data schema based on plexosdb v1.0 (repo: https://github.com/NREL/plexosdb, file: plexosdb/src/plexosdb/schema.sql)
# Ref. documentation: portal.energyexemplar.com/unified-help/plexos-desktop/Article.DatabaseSchema.html
# Table                Layer   Description    
# t_config         Master/Data 	Miscellaneous configuration information for the database such as Revision number
# t_class_group 	    Master 	List of class groups e.g. "Production", "Transmission" groups
# t_class 	            Master 	List of classes e.g. "Generator", "Region", etc
# t_category 	        Data 	List of categories for each class of object e.g. "Generator" might have categories "Thermal" and "Hydro"
# t_unit 	            Master 	List of unit labels for properties e.g. "MW" for the property "Generation"
# t_attribute 	        Master 	List of attributes allowed on each class. Attributes are static values such as "Longitude" and "Latitude" for "Generator" objects
# t_collection 	        Master 	List of collections defining the types of memberships allowed e.g. "Generator" has a "Fuels" collection
# t_property_group 	    Master 	List of property groupings e.g. "Production", "Expansion" properties, etc
# t_property 	        Master 	List of properties allowed on each collection e.g. "Transport Charge" is a property on the "Generator.Fuels" membership type
# t_collection_report 	Master 	List of collections that are inferred from user memberships e.g, a "Generator" belongs to one or more "Region" objects via its "Generator.Nodes" memberships and the "Node.Region" membership
# t_property_report 	Master 	List of report properties e.g. "Generator" has report property ''Generation"
# t_object 	            Data 	List of user-defined objects by class
# t_attribute_data 	    Data 	List of attributes defined on the objects
# t_membership 	        Data 	List of memberships between objects e.g. "Generator" "Thermal" may use "Fuel" "Coal" through the "Generator.Fuels" collection
# t_report 	            Data 	List of report properties selected by the user

#                          name,       fieldname,    fieldtype,            loadorder,  identifer, indexoffset
const plexos_tables = [
    PLEXOSTable("t_action",            :action,            PLEXOSAction,           1, "action_id", 1)
    PLEXOSTable("t_assembly",          :assembly,          PLEXOSAssembly,         1, "assembly_id")
    PLEXOSTable("t_config",            :config,            PLEXOSConfig,           1)
    PLEXOSTable("t_class_group",       :class_group,       PLEXOSClassGroup,       1, "class_group_id")
    PLEXOSTable("t_class",             :class,             PLEXOSClass,            2, "class_id")
    PLEXOSTable("t_category",          :category,          PLEXOSCategory,         3, "category_id")
    PLEXOSTable("t_unit",              :unit,              PLEXOSUnit,             1, "unit_id", 1)
    PLEXOSTable("t_attribute",         :attribute,         PLEXOSAttribute,        3, "attribute_id")
    PLEXOSTable("t_collection",        :collection,        PLEXOSCollection,       3, "collection_id")
    PLEXOSTable("t_property_group",    :property_group,    PLEXOSPropertyGroup,    3, "property_group_id")
    PLEXOSTable("t_property",          :property,          PLEXOSProperty,         4, "property_id")
    PLEXOSTable("t_collection_report", :collection_report, PLEXOSCollectionReport, 4) # 3 id keys
    PLEXOSTable("t_property_report",   :property_report,   PLEXOSPropertyReport,   5, "property_id")
    PLEXOSTable("t_object",            :object,            PLEXOSObject,           4, "object_id")
    PLEXOSTable("t_attribute_data",    :attribute_data,    PLEXOSAttributeData,    5) # 2 foreign keys as PK
    PLEXOSTable("t_membership",        :membership,        PLEXOSMembership,       5, "membership_id")
    # t_report           # Not implemented
    # t_data_meta        # Not implemented
    PLEXOSTable("t_data",              :data,              PLEXOSData,             6, "data_id")
    PLEXOSTable("t_band",              :band,              PLEXOSBand,             6, "data_id")      
    PLEXOSTable("t_date_from",         :date_from,         PLEXOSDateFrom,         6, "data_id")
    PLEXOSTable("t_date_to",           :date_to,           PLEXOSDateTo,           6, "data_id")
    PLEXOSTable("t_custom_column",     :custom_column,     PLEXOSCustomColumn,     6, "column_id")
    # t_message          # Not implemented
    PLEXOSTable("t_tag",               :tag,               PLEXOSTag,              7, "data_id") # 2 foreign keys as PK
    PLEXOSTable("t_text",              :text,              PLEXOSText,             7, "data_id") # 2 foreign keys as PK
    PLEXOSTable("t_property_tag",      :property_tag,      PLEXOSPropertyTag,      7) # BigInt (powers of 2) used for primary key
    PLEXOSTable("t_memo_object",       :memo_object,       PLEXOSMemoObject,       7) # 2 foreign keys as PK
    # t_custom_rule      # Not implemented
    # t_membership_meta  # Not implemented
    # t_memo_data        # Not implemented
    # t_memo_membership  # Not implemented
    # t_object_meta      # Not implemented
]

const max_loadorder = maximum(x.loadorder for x in plexos_tables)
const plexos_tables_lookup = Dict(x.name => x for x in plexos_tables if !(x.name in IGNORED_TABLES))
const plexos_tables_sym_lu = Dict(x.fieldname => x for x in plexos_tables if !(x.name in IGNORED_TABLES))