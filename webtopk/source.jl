type Source
	data::Vector{Tuple{Symbol, Float64}}
	ltimes::Int
	rtimes::Int

	Source(x::Vector{Symbol}) = begin
		gen_score(x) = (x, rand(0:0.01:1))
		data = sort(map(gen_score, x), lt=(x,y)->x[2]<y[2], rev=true)
		new(data, 0, 0)
	end
end

function lookup(s::Source)
	for i in s.data
		s.ltimes += 1
		produce(i)
	end
end

function lookup(s::Source, x::Symbol)
	s.rtimes += 1
	s.data[findfirst(s.data) do i i[1]==x end]
end

function Base.show(io::IO, s::Source)
	println(io, "线性访问次数: ", s.ltimes)
	println(io, "随机访问次数: ", s.rtimes)
	println(io, " 对象 | 评分 ")
	for i in s.data
		@printf(io, " %-5s %5.2f\n", i[1], i[2])
	end
end