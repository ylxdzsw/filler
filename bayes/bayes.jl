function infer(x::Symbol, dep::Set{Symbol}, row::DataFrameRow, df::DataFrame)
    candidates = df[x] |> each_dropna |> unique

    candidates_with_scores = map(candidates) do c
        r = df[df[x] .== c, :]
        s = mapreduce(*, dep) do i
            sum(r[i] .== row[i]) / nrow(r)
        end
        c, s
    end

    best, Σscore = reduce(candidates_with_scores, ((NA, .0), .0)) do acc, item
        best, Σscore = acc
        best = cadr(item) > cadr(best) ? item : best
        Σscore = Σscore + cadr(item)
        best, Σscore
    end

    car(best), cadr(best) / Σscore
end
