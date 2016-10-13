using DataFrames
using OhMyJulia
using PyCall

include("core/rule.jl")
include("core/fill.jl")
include("bayes/bayes.jl")
include("fetcher/wrapper.jl")

df    = readtable("data/data.csv")
rules = readrules("data/rules.txt", df)

for i in df.colindex.names
    df[i] = map(string, df[i])
end

dict = Dict(:中文 => unique(map(strip, df[:中文])))

pos = rand(size(df, 1)) .> .90

ref = map(strip, df[:中文][pos])

df[:中文][pos] = NA

@time for row = eachrow(df)
    fill!(row, rules, df, dict)
end

result = df[:中文][pos]

for i in 1:length(ref)
    println(ref[i], '\t', result[i])
end

println(mean(!isna(df[:中文][pos])))

println(mean(ref[!isna(result)] .== result[!isna(result)]))
