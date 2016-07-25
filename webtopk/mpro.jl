"""
items: all objects
upperbounds: current upperbounds
scores: scores of indivisual source
"""
function mpro(s::Vector{Source}, k::Int=3; eval::Function=minimum)
	nsources             = length(s)
	results              = Vector{Tuple{Symbol, Float64}}()
	lin1                 = @task lookup(s[1])
	(items, upperbounds) = map(collect, zip(lin1...))
	scores               = map(x->[x], upperbounds)

	while true
		(upperbound, i) = findmax(upperbounds)
		nscore = length(scores[i])
		if nscore == nsources
			upperbounds[i] = -1.0
			push!(results, (items[i], upperbound))
			length(results) == k && break
		else
			push!(scores[i], lookup(s[nscore+1], items[i])[2])
			upperbounds[i] = eval(scores[i])
		end
	end

	results
end