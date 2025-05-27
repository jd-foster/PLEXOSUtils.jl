# PLEXOSSolutionDatasetSummary

eval(Expr(
    :struct, true, :PLEXOSSolutionDatasetSummary, 
    Expr(:block,
        [:($(t.fieldname)::Tuple{Int,Int}) for t in plexos_tables]...,
        :(index_map::IndexMap)
    )
))

PLEXOSSolutionDatasetSummary() =
    PLEXOSSolutionDatasetSummary(((0,0) for _ in 1:length(plexos_tables))..., IndexMap())

function PLEXOSSolutionDatasetSummary(
    zippath::String, xmlname::String=defaultxml(zippath)
)

    resultsarchive = _open_plexoszip(zippath)
    xml = parsexml(resultsarchive[xmlname])
    return PLEXOSSolutionDatasetSummary(xml)

end

function PLEXOSSolutionDatasetSummary(xml::Document)

    summary = PLEXOSSolutionDatasetSummary()

    for element in eachelement(xml.root)

        # Ignore given tables:
        !(element.name in keys(plexos_tables_lookup)) && continue
        
        table = plexos_tables_lookup[element.name]
        count, maxidx = getfield(summary, table.fieldname)

        if isnothing(table.identifier)
            setfield!(summary, table.fieldname, (count + 1, count + 1))
        else
            idx = getchildint(table.identifier, element) + table.indexoffset
            setfield!(summary, table.fieldname, (count + 1, max(maxidx, idx)))
            # Update the Dict that maps our linear index to each PLEXOS data identifier
            index_dict = getfield(summary.index_map, table.fieldname)
            index_dict[getchildint(table.identifier, element)] = count + 1
        end

    end

    return summary

end

==(a::PLEXOSSolutionDatasetSummary, b::PLEXOSSolutionDatasetSummary) = 
    propertynames(a) == propertynames(b) &&
    all(getproperty(a, p) == getproperty(b, p) for p in propertynames(a) if p !== :index_map)