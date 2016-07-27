unshift!(PyVector(pyimport("sys")["path"]), "./fetcher")

@pyimport pattern as Pattern
@pyimport match as Match

const pcache = Dict{Set{Symbol}, Tuple{Vector{Symbol}, AbstractString}}()

function get_pattern(involved::Set{Symbol}, df::DataFrame)
    involved in pcache && return pcache[involved]

    involved = [involved...]
    data = map(eachrow(df)) do row
        map(x->row[x], involved)
    end

    p = Pattern.top_patterns(data)[1]

    pcache[involved] = involved, p
end

function websearch(x::Symbol, dep::Vector{Symbol}, row::Dict{Symbol,Tuple{Any, Float64}}, df::DataFrame)
    involved = [dep..., x]
    pattern = get_pattern(involved, df)

    key = findfirst(x, car(pattern)) - 1 # index difference between julia and python
    Match.search_match(key, map(x->row[x], car(pattern)), cadr(pattern)) |> car
end
