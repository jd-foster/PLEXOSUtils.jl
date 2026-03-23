# Input data schema based on plexosdb v1.x (repo: https://github.com/NREL/plexosdb) 
# Sync with file: plexosdb/src/plexosdb/schema.sql
# Follows PLEXOS v9+.

abstract type AbstractDataset end

"table: `t_assembly`; identifier: `assembly_id`"
struct PLEXOSAssembly
    filename::Union{String, Nothing}
    namespace::Union{String, Nothing}
    is_enabled::Bool

    PLEXOSAssembly(e::Node, ::AbstractDataset) = 
        new(
            getchildstr("filename", e),
            getchildstr("namespace", e),
            getchildbool("is_enabled", e)
        )
end

"table: `t_class_group`; identifier: `class_group_id`"
struct PLEXOSClassGroup
    name::String
    lang_id::Union{Int, Nothing}

    function PLEXOSClassGroup(e::Node, ::AbstractDataset)
        new(
            getchildstr("name", e),
            getchildint("lang_id", e)
        )
    end
end

"table: `t_config`; identifer: `element`"
struct PLEXOSConfig
    element::String
    value::String

    PLEXOSConfig(e::Node, ::AbstractDataset) = 
        new(
            getchildstr("element", e),
            getchildstr("value", e)
        )
end

"table: `t_property_group`; identifier: `property_group_id`"
struct PLEXOSPropertyGroup 
    name::Union{String, Nothing}
    lang_id::Union{Int, Nothing}

    function PLEXOSPropertyGroup(e::Node, ::AbstractDataset)
        new(
            getchildstr("name", e),
            getchildint("lang_id", e)
        )
    end
end

"table: `t_unit`; identifier: `unit_id`"
struct PLEXOSUnit 
    value::String
    default::Union{String, Nothing}
    imperial_energy::Union{String, Nothing}
    metric_level::Union{String, Nothing}
    imperial_level::Union{String, Nothing}
    metric_volume::Union{String, Nothing}
    imperial_volume::Union{String, Nothing}
    description::Union{String, Nothing}
    lang_id::Union{Int, Nothing}

    function PLEXOSUnit(e::Node, ::AbstractDataset)
        new(
            getchildstr("value", e),
            getchildstr("default", e),
            getchildstr("imperial_energy", e),
            getchildstr("metric_level", e),
            getchildstr("imperial_level", e),
            getchildstr("metric_volume", e),
            getchildstr("imperial_volume", e),
            getchildstr("description", e),
            getchildint("lang_id", e),
        )
    end
end

"table: t_action; identifier: action_id"
struct PLEXOSAction
    action_symbol::String

    function PLEXOSAction(e::Node, ::AbstractDataset)
        new(
            getchildstr("action_symbol", e)
        )
    end
end

struct PLEXOSMessage end  # Not implemented

"table: `t_property_tag`; identifer: `tag_id`"
struct PLEXOSPropertyTag
    # tag_id::BigInt
    tag_id::Int
    name::Union{String, Nothing}

    function PLEXOSPropertyTag(e::Node, d::AbstractDataset)
        # Alternative: new(parsechild(BigInt, "tag_id", e), getchildstr("name", e))
        new( # store log2 of the tag_id since they are just powers of 2.
            round(Int, log2(parsechild(BigInt, "tag_id", e))), 
            getchildstr("name", e)
        )
    end

end

struct PLEXOSCustomRule end  # Not implemented

"table: `t_class`; identifer: `class_id`"
struct PLEXOSClass
    name::String
    class_group::PLEXOSClassGroup
    is_enabled::Union{Bool, Nothing}
    lang_id::Union{Int, Nothing}
    description::Union{String, Nothing}
    state::Union{Int, Nothing}
    inherits_from::Union{Int, Nothing}

    function PLEXOSClass(e::Node, d::AbstractDataset)
        new(
            getchildstr("name", e),
            getref("class_group_id", e, d, :class_group),
            getchildbool("is_enabled", e),
            getchildint("lang_id", e),
            getchildstr("description", e),
            getchildint("state", e),
            getchildint("inherits_from", e)
        )
    end
end

"table: `t_collection`; identifier: `collection_id`"
struct PLEXOSCollection
    parent_class::Union{PLEXOSClass, Nothing}
    child_class::Union{PLEXOSClass, Nothing}
    name::Union{String, Nothing}
    min_count::Union{Int, Nothing}
    max_count::Union{Int, Nothing}
    complement_name::Union{String, Nothing}
    complement_min_count::Union{Int, Nothing}
    complement_max_count::Union{Int, Nothing}
    is_enabled::Union{Bool, Nothing}
    is_one_to_many::Union{Bool, Nothing}
    lang_id::Union{Int, Nothing}
    description::Union{String, Nothing}
    complement_description::Union{String, Nothing}
    rank::Union{Int, Nothing}

    # PLEXOS sometimes reports collections without reporting the classes they
    # refer to: if that happens, just leave the classes undefined
    # (collection won't have any members anyways)

    function PLEXOSCollection(e::Node, d::AbstractDataset)
        parent_idx = getchildint("parent_class_id", e)
        child_idx = getchildint("child_class_id", e)

        if checkref(d, :class, parent_idx)
            parent_cls = getref(d, :class, parent_idx)
        else
            @warn "Undefined parent class for: $e"
            parent_cls = nothing
        end
        if checkref(d, :class, child_idx)
            child_cls = getref(d, :class, child_idx)
        else
            @warn "Undefined child class for: $e"
            child_cls = nothing
        end

        return new(
            parent_cls,
            child_cls,
            getchildstr("name", e),
            getchildint("min_count", e),
            getchildint("max_count", e),
            getchildstr("complement_name", e),
            getchildint("complement_min_count", e),
            getchildint("complement_max_count", e),
            getchildbool("is_enabled", e),
            getchildbool("is_one_to_many", e),
            getchildint("lang_id", e),
            getchildstr("description", e),
            getchildstr("complement_description", e),
            getchildint("rank", e),
        )

    end

end

"table: `t_collection_report`; identifier: (`collection_id`, `left_collection_id`, `right_collection_id`)"
struct PLEXOSCollectionReport
    collection_id::PLEXOSCollection
    left_collection_id::PLEXOSCollection
    right_collection_id::PLEXOSCollection
    rule_left_collection_id::Union{Int, Nothing}
    rule_right_collection_id::Union{Int, Nothing}
    rule_id::Union{Int, Nothing}

    function PLEXOSCollectionReport(e::Node, d::AbstractDataset)
        return new(
            getref("collection_id", e, d, :collection),
            getref("left_collection_id", e, d, :collection),
            getref("right_collection_id", e, d, :collection),
            getchildint("rule_left_collection_id", e),
            getchildint("rule_right_collection_id", e),
            getchildint("rule_id", e),
        )
    end

end

"table: `t_property`; identifier: `property_id`"
struct PLEXOSProperty 
    collection::Union{PLEXOSCollection, Nothing}
    property_group::PLEXOSPropertyGroup
    enum_id::Union{Int, Nothing}
    name::Union{String, Nothing}
    unit::PLEXOSUnit
    default_value::Float64
    validation_rule::Union{String, Nothing}
    input_mask::Union{String, Nothing}
    upscaling_method::Union{Int, Nothing}
    downscaling_method::Union{Int, Nothing}
    property_type::Union{Int, Nothing}
    period_type_id::Union{Int, Nothing}
    is_key::Bool
    is_enabled::Bool
    is_dynamic::Bool
    is_multi_band::Bool
    max_band_id::Union{Int, Nothing}
    lang_id::Union{Int, Nothing}
    description::Union{String, Nothing}
    tag::Union{String, Nothing}
    is_visible::Bool

    function PLEXOSProperty(e::Node, d::AbstractDataset)

        if checkref("collection_id", e, d, :collection)
            collection = getref("collection_id", e, d, :collection)
        else
            # PLEXOS sometimes reports properties without reporting the collections they
            # refer to: if that happens, just leave the collections undefined
            # (property won't have any data anyways)
            @warn "Undefined collection for: $e"
            collection = nothing
        end

        new(
            collection,
            getref("property_group_id", e, d, :property_group),
            getchildint("enum_id", e),
            getchildstr("name", e),
            getref("unit_id", e, d, :unit),
            getchildfloat("default_value", e),
            getchildstr("validation_rule", e),
            getchildstr("input_mask", e),
            getchildint("upscaling_method", e),
            getchildint("downscaling_method", e),
            getchildint("property_type", e),
            getchildint("period_type_id", e),
            getchildbool("is_key", e),
            getchildbool("is_enabled", e),
            getchildbool("is_dynamic", e),
            getchildbool("is_multi_band", e),
            getchildint("max_band_id", e),
            getchildint("lang_id", e),
            getchildstr("description", e),
            getchildstr("tag", e),
            getchildbool("is_visible", e),
        )
    end

end

"table: `t_property_report`; identifier: `property_id`"
struct PLEXOSPropertyReport 
    collection::Union{PLEXOSCollection, Nothing}
    property_group::PLEXOSPropertyGroup
    enum_id::Union{Int, Nothing}
    name::Union{String, Nothing}
    summary_name::Union{String, Nothing}
    unit::PLEXOSUnit
    summary_unit_id::Union{Int, Nothing}
    is_period::Bool
    is_summary::Bool
    is_multi_band::Bool
    is_quantity::Bool
    is_LT::Bool
    is_PA::Bool
    is_MT::Bool
    is_ST::Bool
    lang_id::Union{Int, Nothing}
    summary_lang_id::Union{Int, Nothing}
    description::Union{String, Nothing}
    is_visible::Bool

    function PLEXOSPropertyReport(e::Node, d::AbstractDataset)

        if checkref("collection_id", e, d, :collection)
            collection = getref("collection_id", e, d, :collection)
        else
            # PLEXOS sometimes reports properties without reporting the collections they
            # refer to: if that happens, just leave the collections undefined
            @warn "Undefined collection for: $e"
            collection = nothing
        end
        # property_group = getref("property_group_id", e, d, :property_group)

        new(
            collection,
            getref("property_group_id", e, d, :property_group),
            getchildint("enum_id", e),
            getchildstr("name", e),
            getchildstr("summary_name", e),
            getref("unit_id", e, d, :unit),
            getchildint("summary_unit_id", e),
            getchildbool("is_period", e),
            getchildbool("is_summary", e),
            getchildbool("is_multi_band", e),
            getchildbool("is_quantity", e),
            getchildbool("is_LT", e),
            getchildbool("is_PA", e),
            getchildbool("is_MT", e),
            getchildbool("is_ST", e),
            getchildint("lang_id", e),
            getchildint("summary_lang_id", e),
            getchildstr("description", e),
            getchildbool("is_visible", e),
        )
    end

end

"table: `t_custom_column`; identifier: `column_id`"
struct PLEXOSCustomColumn
    class::PLEXOSClass
    name::Union{String, Nothing}
    position::Union{Int, Nothing}
    GUID::Union{String, Nothing}

    function PLEXOSCustomColumn(e::Node, d::AbstractDataset)
        new(
            getref("class_id", e, d, :class),
            getchildstr("name", e),
            getchildint("position", e),
            getchildstr("GUID", e)
        )
    end

end

"table: `t_attribute`; identifier: `attribute_id`"
struct PLEXOSAttribute
    class::Union{PLEXOSClass, Nothing}
    enum_id::Int
    name::Union{String, Nothing}
    unit::PLEXOSUnit
    default_value::Union{Float64, Nothing}
    validation_rule::Union{String, Nothing}
    input_mask::Union{String, Nothing}
    is_enabled::Bool
    is_integer::Bool
    lang_id::Int
    description::Union{String, Nothing}
    tag::Union{String, Nothing}
    is_visible::Bool

    function PLEXOSAttribute(e::Node, d::AbstractDataset)
        class_idx = getchildint("class_id", e)
        if !isnothing(class_idx) && checkref(d, :class, class_idx)
            this_class = getref(d, :class, class_idx)
        else
            # PLEXOS sometimes reports attributes without reporting the classes they
            # refer to: if that happens, just leave the classes undefined
            this_class = nothing
        end

        return new(
            this_class,
            getchildint("enum_id", e),
            getchildstr("name", e),
            getref("unit_id", e, d, :unit),
            getchildfloat("default_value", e),
            getchildstr("validation_rule", e),
            getchildstr("input_mask", e),
            getchildbool("is_enabled", e),
            getchildbool("is_integer", e),
            getchildint("lang_id", e),
            getchildstr("description", e),
            getchildstr("tag", e),
            getchildbool("is_visible", e),
        )
    end
end

"table: `t_category`; identifier: `category_id`"
struct PLEXOSCategory
    class::Union{PLEXOSClass, Nothing}
    rank::Union{Int, Nothing}
    name::Union{String, Nothing}
    state::Union{Int, Nothing}

    function PLEXOSCategory(e::Node, d::AbstractDataset)
        class_idx = getchildint("class_id", e)
        if !isnothing(class_idx) && checkref(d, :class, class_idx)
            this_class = getref(d, :class, class_idx)
        else
            # PLEXOS sometimes reports categories without reporting the classes they
            # refer to: if that happens, just leave the class undefined
            # (category won't have any objects anyways)
            this_class = nothing
        end

        return new(
            this_class,
            getchildint("rank", e),
            getchildstr("name", e),
            getchildint("state", e)
        )

    end

end

"table: `object_id`; identifier: `t_object`"
struct PLEXOSObject
    class::PLEXOSClass
    name::String
    category::PLEXOSCategory
    description::Union{String, Nothing}
    GUID::Union{String, Nothing}
    state::Union{Int, Nothing}
    X::Union{Int, Nothing}
    Y::Union{Int, Nothing}
    Z::Union{Int, Nothing}

    function PLEXOSObject(e::Node, d::AbstractDataset)
        new(
            getref("class_id", e, d, :class),
            getchildstr("name", e),
            getref("category_id", e, d, :category),
            getchildstr("description", e),
            getchildstr("GUID", e),
            getchildint("state", e),
            getchildint("X", e),
            getchildint("Y", e),
            getchildint("Z", e),
        )
    end

end

"table: `t_memo_object`; identifier: (`object_id`, `column_id`)"
struct PLEXOSMemoObject
    object::PLEXOSObject
    column::PLEXOSCustomColumn
    value::Union{String, Nothing}
    state::Union{Int, Nothing}

    function PLEXOSMemoObject(e::Node, d::AbstractDataset)

        object_idx = getchildint("object_id", e)
        column = getref("column_id", e, d, :custom_column)
        value = getchildstr("value", e)
        state = getchildint("state", e)

        if checkref(d, :object, object_idx)
            object = getref(d, :object, object_idx)
        else
            @warn "Undefined object class for: $e"
            object = nothing
        end
        new(
            object,
            column,
            value,
            state
        )

    end

end

struct PLEXOSReport end       # Not implemented
struct PLEXOSObjectMeta end   # Not implemented

"table: `t_attribute_data`; identifier: (`object_id`, `attribute_id`)"
struct PLEXOSAttributeData
    object::Union{PLEXOSObject, Nothing}
    attribute::PLEXOSAttribute
    value::Float64
    state::Union{Int, Nothing}

    function PLEXOSAttributeData(e::Node, d::AbstractDataset)       
        object_idx = getchildint("object_id", e)
        if checkref(d, :object, object_idx)
            object_ref = getref(d, :object, object_idx)
        else
            # PLEXOS sometimes reports attributes without reporting the objects they
            # refer to: if that happens, just leave the objects undefined
            @warn "Undefined object for: $e"
            object_ref = nothing
        end
        attribute_ref = getref("attribute_id", e, d, :attribute)

        new(
            object_ref,
            attribute_ref,
            getchildfloat("value", e),
            getchildint("state", e)
        )
    end

end

"table: `t_membership`; identifier: `membership_id`"
struct PLEXOSMembership
    parent_class::PLEXOSClass
    parent_object::PLEXOSObject
    collection::PLEXOSCollection
    child_class::PLEXOSClass
    child_object::PLEXOSObject
    state::Union{Int, Nothing}

    function PLEXOSMembership(e::Node, d::AbstractDataset)
        new(
            getref("parent_class_id", e, d, :class),
            getref("parent_object_id", e, d, :object),
            getref("collection_id", e, d, :collection),
            getref("child_class_id", e, d, :class),
            getref("child_object_id", e, d, :object),
            getchildint("state", e),
        )
    end
end

# t_memo_membership  # Not implemented
# t_membership_meta  # Not implemented

"table: `t_data`; identifier: `data_id`"
struct PLEXOSData
    membership::PLEXOSMembership
    property::PLEXOSProperty
    value::Union{Float64, Nothing}
    state::Union{Int, Nothing}
    uid::Union{BigInt, Nothing}

    function PLEXOSData(e::Node, d::AbstractDataset)
        new(
            getref("membership_id", e, d, :membership),
            getref("property_id", e, d, :property),
            getchildfloat("value", e),
            getchildint("state", e),
            parsechild(BigInt, "uid", e)
        )
    end
    
end

"table: `t_date_from`; identifier: `data_id`"
struct PLEXOSDateFrom
    date::DateTime
    state::Union{Int, Nothing}

    function PLEXOSDateFrom(e::Node, d::AbstractDataset)
        new(
            getchilddatetime("date", e),
            getchildint("state", e)
        )
    end

end

"table: `t_date_to`; identifier: `data_id`"
struct PLEXOSDateTo 
    date::DateTime
    state::Union{Int, Nothing}

    function PLEXOSDateTo(e::Node, d::AbstractDataset)
        new(
            getchilddatetime("date", e),
            getchildint("state", e)
        )
    end

end

"table: `t_tag``; identifier: (`data_id`, `object_id`)"
struct PLEXOSTag
    object::PLEXOSObject
    state::Union{Int, Nothing}
    action::Union{PLEXOSAction, Nothing}

    function PLEXOSTag(e::Node, d::AbstractDataset)
        
        if checkref("action_id", e, d, :action)
            action = getref("action_id", e, d, :action)
        else
            action = nothing
        end

        new(
            getref("object_id", e, d, :object),
            getchildint("state", e),
            action,
        )
    end

end

"table: `t_text`; identifier: (`data_id`, `class_id`)"
struct PLEXOSText
    class::PLEXOSClass
    value::Union{String, Nothing}
    state::Union{Int, Nothing}
    action::Union{PLEXOSAction, Nothing}

    function PLEXOSText(e::Node, d::AbstractDataset)

        if checkref("action_id", e, d, :action)
            action = getref("action_id", e, d, :action)
        else
            action = nothing
        end

        new(
            getref("class_id", e, d, :class),
            getchildstr("value", e),
            getchildint("state", e),
            action,
        )
    end

end

struct PLEXOSMemoData end            # Not implemented
struct PLEXOSDataMeta end       # Not implemented

"table: `t_band`; identifier: `data_id`"
struct PLEXOSBand
        band_id::Int
        state::Union{Int, Nothing}

    function PLEXOSBand(e::Node, d::AbstractDataset)
        new(
            getchildint("band_id", e),
            getchildint("state", e)
        )
    end

end