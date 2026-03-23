function open_plexoszip(zippath::String, xmlname::String=defaultxml(zippath);
    consolidated::Bool=false)
    resultsarchive = _open_plexoszip(zippath)
    xml = parsexml(resultsarchive[xmlname])

    summ = PLEXOSSolutionDatasetSummary(xml)
    data = PLEXOSSolutionDataset(xml; summary=summ, consolidated=consolidated)

    return data, summ

end

function _open_plexoszip(zippath::String)
    isfile(zippath) || error("$zippath does not exist")
    return open_zip(zippath)
end

defaultxml(zippath::String) = replace(basename(zippath), r".zip$"=>".xml")

# Usage:
    # resultsarchive = _open_plexoszip(zippath)
#     resultvalues = perioddata(resultsarchive)
function perioddata(archive::Dict{String,Vector{UInt8}})
    results = Dict{Int,Vector{UInt8}}()
    for filename in keys(archive)
        rgx = match(r"t_data_(\d).BIN", filename)
        isnothing(rgx) && continue
        data = archive[filename]
        results[parse(Int, rgx[1])] = data
    end
    return results
end

function getchildstr(name::String, e::Node; prefix::String="x")
    resultnode = findfirst(prefix *":"* name, e, [prefix=>namespace(e)])
    isnothing(resultnode) && return nothing # ArgumentError("Empty result on node $(e) for name '$(name)'")
    return nodecontent(resultnode)
end

function parsechild(T::DataType, name::String, e::Node)
    text = getchildstr(name, e)
    isnothing(text) && return nothing
    try
        parse(T, text)
    catch
        @warn "Unable to parse '$(name)' for node\n$(e)\n as type `$(T)`"
        error()
    end 
    return parse(T, text)
end

getchildfloat(name::String, e::Node) = parsechild(Float64, name, e)
getchildint(name::String, e::Node) = parsechild(Int, name, e)
getchildbool(name::String, e::Node) = parsechild(Bool, name, e)
getchilddatetime(name::String, e::Node) = parse(DateTime, getchildstr(name, e))

function getref(dataset::AbstractDataset, tablename::Symbol, idx::Integer)
    if dataset.consolidated[] # de-reference Bool value
        lookup_idx = getfield(dataset.index_map, tablename)[idx]
        return getfield(dataset, tablename)[lookup_idx]
    else
        table_offset = plexos_tables_sym_lu[tablename].indexoffset
        return getfield(dataset, tablename)[idx + table_offset]
    end
end

# Note: we always assume that the referencing index is an integer.
function getref(name::String, e::Node, d::AbstractDataset, tablename::Symbol)
    getref(d, tablename, getchildint(name, e))
end

function checkref(dataset::AbstractDataset, tablename::Symbol, idx::Integer)
    if dataset.consolidated[] # de-reference Bool value
        return haskey(getfield(dataset.index_map, tablename), idx)
    else
        return isassigned(getfield(dataset, tablename), idx)
    end
end

checkref(dataset::AbstractDataset, tablename::Symbol, ::Nothing) = false
checkref(name::String, e::Node, d::AbstractDataset, tablename::Symbol) = checkref(d, tablename, getchildint(name, e))

"Convert a PLEXOSTable instance to a nested ordered dictionary of values"
function instance_to_dict(inst)
    return OrderedDict(x => instance_to_dict(getfield(inst, x)) for x in propertynames(inst))
end

instance_to_dict(x::Number) = x
instance_to_dict(x::String) = x
instance_to_dict(::Nothing) = nothing

function check_and_print_dataset(dataset::PLEXOSSolutionDataset, summ::PLEXOSSolutionDatasetSummary)
    total = 0

    println("Summary: (count, max. index)")
    for i in propertynames(summ)
        (i == :index_map) && continue
        t = getfield(summ,i)
        if !isempty(t)
            println("\t$i: $t")
            total += first(t)
        end
    end

    for i in propertynames(dataset)
        (i in [:index_map,:consolidated]) && continue
        t = getfield(summ,i)
        if !isempty(t)
            s = getfield(dataset,i)
            # println("\t$i: $t, $(length(s))")
            @assert last(t) == length(s)
        end
    end

    println("Empty:")
    for i in propertynames(dataset)
        (i == :index_map) && continue
        t = getfield(dataset,i)
        if isempty(t)
            println("\t$i")
        end
    end

    println("Not empty: max. index")
    for i in propertynames(dataset)
        (i == :index_map) && continue
        t = getfield(dataset,i)
        if !isempty(t)
            println("\t$i: $(length(t))")
        end
    end

    return total
end