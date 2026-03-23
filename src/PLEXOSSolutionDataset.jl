# PLEXOSSolutionDataset

eval(Expr(
    :struct, false, :(PLEXOSSolutionDataset <: AbstractDataset),
    Expr(:block,
        [:($(t.fieldname)::Vector{$(t.fieldtype)}) for t in plexos_tables]...,
        :(index_map::IndexMap),
        :(consolidated::Ref{Bool})
    )
))

function PLEXOSSolutionDataset(
    zippath::String, xmlname::String=defaultxml(zippath);
    consolidated::Bool=false)

    resultsarchive = _open_plexoszip(zippath)
    xml = parsexml(resultsarchive[xmlname])
    return PLEXOSSolutionDataset(xml; consolidated=consolidated)
end

function PLEXOSSolutionDataset(xml::Document; summary=nothing, consolidated::Bool=false)

    if isnothing(summary)
        summary = PLEXOSSolutionDatasetSummary(xml)
    end
    # Initialise:
    result = PLEXOSSolutionDataset(summary, consolidated=consolidated)
    idxcounter = IndexCounter()

    # Load data:
    for loadorder in 1:max_loadorder
        for element in eachelement(xml.root)

            # Ignore given tables:
            !(element.name in keys(plexos_tables_lookup)) && continue

            table = plexos_tables_lookup[element.name]
            table.loadorder == loadorder || continue

            if isnothing(table.identifier)
                idx = increment!(idxcounter, table.fieldname)
            elseif consolidated
                lookup_idx = getchildint(table.identifier, element)
                idx = getfield(result.index_map, table.fieldname)[lookup_idx]
            else
                idx = getchildint(table.identifier, element) + table.indexoffset
            end

            getfield(result, table.fieldname)[idx] = (table.fieldtype)(element, result)

        end
    end

    result.consolidated[] = consolidated # de-reference Bool value
    return result
end

function PLEXOSSolutionDataset(
    summary::PLEXOSSolutionDatasetSummary;
    consolidated::Bool=false)

    selector = consolidated ? first : last

    return PLEXOSSolutionDataset(
            (Vector{t.fieldtype}(undef, selector(getfield(summary, t.fieldname)))
            for t in plexos_tables)...,
            summary.index_map,
            consolidated
           )

end

==(a::PLEXOSSolutionDataset, b::PLEXOSSolutionDataset) = 
    propertynames(a) == propertynames(b) && 
    a.consolidated[] == b.consolidated[] &&
    getdict(a.index_map) == getdict(b.index_map)
    ## This is much stronger but trickier to enforce if there are undefined references:
    # all(getproperty(a, p) == getproperty(b, p) for p in propertynames(a) if !(p in [:index_map, :consolidated]))
    
function consolidate(
    unconsolidated::PLEXOSSolutionDataset,
    summary::PLEXOSSolutionDatasetSummary)

    if unconsolidated.consolidated[] # de-reference Bool value
        @info "PLEXOSSolutionDataset object already consolidated"
        return unconsolidated
    end

    index_map = unconsolidated.index_map

    result = PLEXOSSolutionDataset(summary, consolidated=true)
    for name in keys(plexos_tables_sym_lu)

        values = getfield(unconsolidated, name)
        
        if hasfield(index_map, name)
            index_lookup = keys(getfield(index_map, name))
        else
            index_lookup = 1:length(values)
        end
        
        indexoffset = plexos_tables_sym_lu[name].indexoffset
        if indexoffset !== 0
            index_lookup = collect(index_lookup) .+ indexoffset
        end

        for (i, idx) in enumerate(index_lookup)
            getfield(result, name)[i] = values[idx]
        end
    end

    result.consolidated[] = true # de-reference Bool value
    return result

end

"Accessing data while handling if it is consolidated (or not)."
function get_valid_data(dataset::PLEXOSSolutionDataset, field::Symbol)
    if dataset.consolidated[]
        return getfield(dataset, field)
    else
        index_set = collect( keys( getfield(dataset.index_map, field) ) )
        return getfield(dataset, field)[index_set]
    end
end