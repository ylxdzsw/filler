include("source.jl")
include("mpro.jl")

items = [:a, :b, :c, :d, :e, :f]
s1    = Source(items)
s2    = Source(items)
s3    = Source(items)

topk  = mpro([s1, s2, s3])

@show topk
@show s1
@show s2
@show s3
