unshift!(PyVector(pyimport("sys")["path"]), "")
unshift!(PyVector(pyimport("sys")["path"]), "./fetcher")

@pyimport pattern as Pattern
@pyimport match as Match
@pyimport search as searcher

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

# function websearch(x::Symbol, dep::Vector{Symbol}, row::Dict{Symbol,Tuple{Any, Float64}}, df::DataFrame, dict::Dict)
#     pattern = get_pattern([dep..., x], df)
#
#     key = findfirst(car(pattern), x) - 1 # index difference between julia and python
#
#     contains(cadr(pattern), "\$$key") || return ""
#
#     r = Match.search_match(key, map(x->string(car(row[x])), car(pattern)), cadr(pattern)) |> car
#
#     c = dict[x][map(p->contains(p, r), dict[x]) |> Vector{Bool}]
#
#     if length(c) == 0
#         return ""
#     else
#         sort(c, by=length)[1]
#     end
# end

function websearch(x::Symbol, dep::Vector{Symbol}, row::Dict{Symbol,Tuple{Any, Float64}}, df::DataFrame, dict::Dict)
    query = [map(x->car(row[x]), dep)..., x]

    candidates = let
        a = Dict()
        for i in dict[x]
            a[i] = 0
        end
        a
    end

    for i in searcher.search(query)
        for j in keys(candidates)
            if contains(i, j)
                candidates[j] += 1
            end
        end
    end

    r = sort(collect(candidates), by=x->x.second, rev=true)[1]

    if r.second == 0
        return ""
    else
        r.first
    end
end
