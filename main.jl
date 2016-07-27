using DataFrames
using OhMyJulia
using PyCall

include("core/rule.jl")
include("core/fill.jl")

df    = readtable("data/data.csv")
rules = readrules("data/rules.txt", df)

for row in df
