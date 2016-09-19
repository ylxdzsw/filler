using DataFrames
using OhMyJulia
using PyCall

include("core/rule.jl")
include("core/fill.jl")
include("bayes/bayes.jl")
include("fetcher/wrapper.jl")

df    = readtable("data/data.csv")
rules = readrules("data/rules.txt", df)

pos = rand(size(df, 1)) .> .95

df[:Coaches][pos] = NA

@time for row = eachrow(df)
    fill!(row, rules, df)
end

df[:Coaches][pos]
