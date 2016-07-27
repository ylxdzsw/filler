unshift!(PyVector(pyimport("sys")["path"]), "")
unshift!(PyVector(pyimport("sys")["path"]), "./fetcher")

@pyimport pattern as Pattern
@pyimport match as Match

const pcache = Dict{Set{Symbol}, Tuple{Vector{Symbol}, AbstractString}}()

function get_pattern(involved::Vector{Symbol}, df::DataFrame)
    involved_set = Set(involved)
    involved_set in keys(pcache) && return pcache[involved_set]

    data = map(eachrow(df)) do row
        map(x->row[x], involved)
    end

    data = filter(data) do x !any(isna, x) end

    p = Pattern.top_patterns(data)[2]

    pcache[involved_set] = involved, car(p)
end

function websearch(x::Symbol, dep::Vector{Symbol}, row::Dict{Symbol,Tuple{Any, Float64}}, df::DataFrame)
    pattern = get_pattern([dep..., x], df)

    key = findfirst(car(pattern), x) - 1 # index difference between julia and python

    contains(cadr(pattern), "\$$key") || return ""

    Match.search_match(key, map(x->string(car(row[x])), car(pattern)), cadr(pattern)) |> car
end
