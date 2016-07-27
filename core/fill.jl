import Base.fill!

function fill!(row::DataFrameRow, rules::Vector{Rule}, df::DataFrame; minconfidence::Float64=.6)
    results = Dict{Symbol,Tuple{Any, Float64}}()

    searchfor(x::Symbol) = begin
        if x in keys(results)
            return results[x]
        end

        if !isna(row[x])
            return results[x] = row[x], 1.
        end

        results[x] = NA, 0.

        candidates = map(rules) do r
            for (s,f) in r.condition
                v,c = searchfor(s)
                v === true || return r, 0.
            end

            conf = r.confidence * mapreduce(cadr ∘ searchfor, *, r.dependency)
            r, conf
        end

        best, conf = reduce((nothing, minconfidence), candidates) do x,y
            cadr(x) > cadr(y) ? x : y
        end

        best == nothing && return results[x]

        v,c = infer(x, best.dependency, results, df)

        c * conf > minconfidence && return v, c * conf

        v = websearch()

        v == "" ? (NA, 0.) : (v, conf)
    end

    for x in names(row)
        row[x] = searchfor(x) |> car
    end
end
