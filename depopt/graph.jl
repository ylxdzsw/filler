typealias Dep Tuple{Int, Float64, Float64}

function gengraph(rules::Vector{Rule})
    # (field, [(dependency, confidence, support)])
    nodes = Tuple{Symbol, Vector{Dep}}[]
    namedict = Dict{Symbol, Int}()

    genlogicnode(x::Vector{Int}) = push!(nodes, (:&, map(x->(x,-1.,-1.), x))) |> length

    getnode(x::Symbol) = begin
        i = get(namedict, x, 0)
        i != 0 ? i : namedict[x] = push!(nodes, (x, Dep[])) |> length
    end

    for r in rules
        x = getnode(r.var)
        deps = [r.dependency; map(car, r.condition)] |> unique
        y = length(deps) > 1 ? map(getnode, deps) |> genlogicnode : deps[1] |> getnode
        push!(cadr(nodes[x]), (y, r.confidence, r.support))
    end

    nodes
end

function gengraphviz(G::Vector{Tuple{Symbol, Vector{Dep}}})
    buf = IOBuffer()
    println(buf, "digraph Dependency {")
    for (i,node) in enumerate(G)
        logic = !isempty(node[2]) && node[2][1][2] < 0. # whether a "&" node, by checking if confidence < 0
        print(buf, "\tn", i, " [label=\"", car(node), "\" shape=", logic?"box":"ellipse", "]\n")
        for (index, confidence, support) in cadr(node)
            print(buf, "\tn", index, " -> n", i)
            logic || @printf(buf, " [label=\"%.1f%%, %.1f%%\"]", 100confidence, 100support)
            println(buf)
        end
    end
    println(buf, '}')
    buf |> seekstart |> readall
end
