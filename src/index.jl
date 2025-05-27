# Index tracking

# IndexMap

eval(Expr(
    :struct, true, :IndexMap, Expr(:block,
        [:($(t.fieldname)::OrderedDict{Int,Int}) for t in plexos_tables if !isnothing(t.identifier)]...
    )
))

IndexMap() = IndexMap([OrderedDict{Int,Int}() for _ in 1:length(fieldnames(IndexMap))]...)

Base.hasfield(::IndexMap, name::Symbol) = (name in fieldnames(IndexMap))

getdict(idxmap::IndexMap) = OrderedDict(p => getfield(idxmap, p) for p in propertynames(idxmap))

# IndexCounter

eval(Expr(
    :struct, true, :IndexCounter, Expr(:block,
        [:($(t.fieldname)::Int) for t in plexos_tables if isnothing(t.identifier)]...
    )
))

IndexCounter() = IndexCounter(zeros(Int, length(fieldnames(IndexCounter)))...)

function increment!(x::IndexCounter, fieldname::Symbol)
    idx = getfield(x, fieldname) + 1
    setfield!(x, fieldname, idx)
    return idx
end

