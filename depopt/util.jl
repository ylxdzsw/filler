car(x::Tuple) = x[1]
cdr(x::Tuple) = x[2:end]
cadr(x::Tuple) = x[2]

splitby(y) = x -> split(x, y)

∘(f::Function, g::Function) = x->f(g(x))
