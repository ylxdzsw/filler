import DataFrames.Terms

immutable Rule
    var::Symbol
    dependency::Vector{Symbol}
    condition::Vector{Tuple{Symbol,Function}} # 条件之间都是与的关系，或可以通过拆成两个rule来实现
    formula::Nullable{Function}
    confidence::Float64
end

function parse_rule(p::AbstractString, c::AbstractString, func::AbstractString, data::DataFrame)
    l, r = parse_formula(p)
    cond = parse_condition(c)
    func = rstrip(func)

    if endswith(func, '%')
        form = nothing
        conf = parse(Float64, func[1:end-1]) / 100
    else
        form = Expr(:->, Expr(:tuple, args...), parse(func)) |> eval

        df = reduce(data, cond) do x,y
            matches = map(cadr(y), x[car(y)]) |> each_replacena(false) |> collect
            x[matches |> Vector{Bool}, :] # maybe BitVector will be faster?
        end

        conf = df[l] .== map(eachrow(df)) do x form(map(cadr, x[r])...) end
        conf = conf |> dropna |> mean
    end

    Rule(l, r, cond, Nullable{Function}(form), conf)
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

function readrules(file::AbstractString, df::DataFrame)
    lines = open(readlines, file)
    map(lines) do x
        x = split(x, ';')
        parse_rule(x..., df)
    end
end
