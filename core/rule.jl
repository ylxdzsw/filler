import DataFrames.Terms

immutable Rule
    var::Symbol
    dependency::Vector{Symbol}
    condition::Vector{Tuple{Symbol,Function}} # 条件之间都是与的关系，或可以通过拆成两个rule来实现
    formula::Function
    confidence::Float64
    support::Float64
end

function parse_rule(p::AbstractString, c::AbstractString, func::AbstractString, data::DataFrame)
    l, r = parse_formula(p)
    cond = parse_condition(c)
    form = parse_function(r, func)

    df = reduce(data, cond) do x,y
        matches = map(cadr(y), x[car(y)]) |> each_replacena(false) |> collect
        x[matches |> Vector{Bool}, :] # maybe BitVector will be faster?
    end

    confidence = df[l] .== map(eachrow(df)) do x form(map(cadr, x[r])...) end
    confidence = confidence |> dropna
    support = length(confidence) / nrow(data)
    confidence = mean(confidence)

    Rule(l, r, cond, form, confidence, support)
end

function parse_formula(x::AbstractString)
    t = x |> parse |> eval |> Terms
    @assert length(t.eterms) - length(t.terms) == 1
    setdiff(t.eterms, t.terms)[1], t.terms |> Vector{Symbol}
end

function parse_condition(x::AbstractString)
    gen_condition(::Void) = Tuple{Symbol,Function}[]
    gen_condition(x::Expr) = begin
        if x.head == :comparison
            Tuple{Symbol,Function}[genfun(x)]
        elseif x.head == :tuple
            Tuple{Symbol,Function}[genfun(x) for x in x.args]
        else
            error("unexpected condition expression")
        end
    end
    parse(x) |> gen_condition
end

const comparators = map(Symbol, ["==", "!=", ">", "<", "<=", ">="])

nona(f) = (args...) -> any(isna, args) ? NA : f(args...)

function genfun(x::Expr)
    @assert x.head == :comparison

    isfreevar(::Any) = false
    isfreevar(x::Symbol) = x ∉ comparators

    i = findfirst(isfreevar, x.args)
    let s = x.args[i]
        s, Expr(:->, s, x) |> eval |> nona
    end
end

function parse_function(args::Vector{Symbol}, body::AbstractString)
    Expr(:->, Expr(:tuple, args...), parse(body)) |> eval
end

function meet(rule::Rule, row::DataFrameRow)
    for (s,f) in rule.condition
        if isna(row[s])
            return NA
        elseif f(row[s])
            continue
        else
            return false
        end
    end

    true
end
