fuckNA(x) = Bool[!isna(x) ? x : false for x in x]

function infer(x::Symbol, dep::Vector{Symbol}, row::Dict{Symbol,Tuple{Any, Float64}}, df::DataFrame)
    candidates = df[x] |> each_dropna |> unique

    candidates_with_scores = map(candidates) do c
        r = df[fuckNA(df[x] .== c), :]
        s = mapreduce(*, dep) do i
            sum(fuckNA(r[i] .== car(row[i]))) / size(r, 1)
        end
        c, s
    end

    best, Σscore = reduce(((NA, .0), .0), candidates_with_scores) do acc, item
        best, Σscore = acc
        best = cadr(item) > cadr(best) ? item : best
        Σscore = Σscore + cadr(item)
        best, Σscore
    end

    car(best), cadr(best) / Σscore
end
