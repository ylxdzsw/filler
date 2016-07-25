abstract Plan

immutable DDplan <: Plan end # Direct Determined

immutable DIplan <: Plan end # Direct Indetermined

immutable IDplan <: Plan # Indirect Determined
    path::Rule
    confidence::Float64
end

immutable IIplan <: Plan # Indirect Indetermined
    paths::Vector{Rule}
    confidence::Float64
end

immutable Fakeplan <: Plan end # used to circumvent dead loops

confidence(p::Plan) = p.confidence # confidence upper bound
confidence(p::DDplan) = 1.
confidence(p::DIplan) = 1.
confidence(p::Fakeplan) = 0.

determined(p::Plan) = false
determined(p::DDplan) = true
determined(p::IDplan) = true

function makeplan(rules::Vector{Rule}; minconfidence::Float64=0.1)
    depdict = Dict{Symbol, Vector{Rule}}()
    for x in rules
        i = get(depdict, x.var, Rule[])
        depdict[x.var] = push!(i, x)
    end

    row::DataFrameRow -> begin
        plan = Dict{Symbol, Plan}()
        searchfor(x::Symbol) = begin
            if x in keys(plan)
                return plan[x]
            end

            if !isna(row[x])
                return plan[x] = DDplan()
            end

            plan[x] = Fakeplan()

            candidates = Tuple{Rule, Float64}[]
            for r in get(depdict, x, Rule[])
                met = meet(r, row)
                !isna(met) && !met && continue
                c = isempty(r.dependency) ? 1 : mapreduce(confidence ∘ searchfor, *, r.dependency)
                c * r.confidence >= minconfidence && push!(candidates, (r, c * r.confidence))
            end
            sort!(candidates, lt=(x,y)->cadr(x)<cadr(y), rev=true)

            plan[x] = if isempty(candidates)
                DIplan()
            elseif all(determined ∘ searchfor, car(candidates[1]).dependency)
                IDplan(candidates[1]...)
            else
                IIplan(map(car, candidates), cadr(candidates[1]))
            end
        end
        map(searchfor, names(row))
        plan
    end
end

function exec!(row::DataFrameRow, plans::Dict{Symbol, Plan}, websearch::Function)
    results = Dict{Symbol, Tuple{Any, Float64}}()
    exec(s::Symbol) = s in keys(results) ? results[s] : results[s] = exec(s, plans[s])
    exec(s::Symbol, plan::DDplan) = row[s], 1.
    exec(s::Symbol, plan::DIplan) = websearch(row, s)
    exec(s::Symbol, plan::IDplan) = let r = plan.path
        # TODO: should read from `results` rather tha `row`
        r.formula(map(cadr, row[r.dependency])...), plan.confidence
    end
    exec(s::Symbol, plan::IIplan) = begin
        t = plan.paths
        t = filter(t) do x
            map(exec ∘ car, x.condition)
            map(x->x[2](results[x[1]][1]), x.condition) |> all
        end
        t = map(t) do x
            isempty(x.dependency) && return x.formula(), 1.
            p = map(exec, x.dependency)
            x.formula(map(car, p)...), mapreduce(cadr, *, p)
        end
        #TODO: if confidence is too low, search web and compare
        sort(t, lt=(x,y)->cadr(x)<cadr(y), rev=true)[1]
    end

    map(names(row)) do x
        isna(row[x]) && (row[x] = (car ∘ exec)(x))
    end
end

function exec!(websearch::Function)
    r::Tuple{DataFrameRow, Dict{Symbol, Plan}} -> exec!(car(r), cadr(r), websearch)
end
