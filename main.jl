using DataFrames

include("util.jl")
include("rule.jl")
include("graph.jl")
include("plan.jl")

df_raw = readtable("demo/data.csv")
df = [df_raw; df_raw; df_raw]
for i in names(df)
    df[rand(1:nrow(df), 3000), i] = NA
end

rules = open(readlines, "demo/rule.txt")
rules = map(splitby(";"), rules)
rules = map(rules) do x parse_rule(x..., df) end

websearch(data::DataFrameRow, s::Symbol) = begin
    queries = filter(names(data)) do x !isna(data[x]) end
    if isempty(queries) return NA, 0. end
    matches = mapreduce(&, queries) do x
        df_raw[x] .== data[x]
    end
    results = df_raw[matches, s]
    mode(results), mean(results .== mode(results))
end
# 1. 不依赖任何属性可以用常数(比如1)写在右侧
# 2. 条件只支持一个属性和常量比较
# 3. 等于条件用"=="，不等于可以用"≠"或者"!="
# 4. 多个条件用逗号连接, 这样连接是"与"逻辑, 或逻辑可以拆成多个规则
# 5. 支持类似"4 < X < 5"这样的表达式
