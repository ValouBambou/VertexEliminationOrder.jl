using MPI 
ENV["JULIA_MPI_BINARY"]="system"
using VertexEliminationOrder

graph_name = "sycamore_53_20.gr"
duration = 30
max_imbalances = [1.0, 0.8, 0.6]
base_seed = 42
seed_diff = 1000
base_nsample=20
sample_augment=8

i = 1
n = length(ARGS)
while i <= n
	global i, graph_name, duration, base_seed, base_nsample, sample_augment, seed_diff, max_imbalances
	if ARGS[i] =="--duration" duration = parse(Int64, ARGS[i+1]) end
	if ARGS[i] =="--graph" graph_name = ARGS[i+1] end
    if ARGS[i] =="--seed" base_seed = parse(Int64, ARGS[i+1]) end
	if ARGS[i] =="--seeddiff" seed_diff = parse(Int64, ARGS[i+1]) end
    if ARGS[i] =="--nsample" base_nsample = parse(Int64, ARGS[i+1]) end
    if ARGS[i] =="--nsampleplus" sample_augment = parse(Int64, ARGS[i+1]) end
    if ARGS[i] =="--imbalances" max_imbalances = [parse(Float64, ss) for ss in split(ARGS[i+1], ",")] end
    i += 1
end

println("- - - args - - -")
println("duration = $duration")
println("max_imbalances = $max_imbalances") 
println("base_seed = $base_seed")
println("seed_diff = $seed_diff")
println("base_nsample = $base_nsample")
println("sample_augment = $sample_augment")
println("- - - result - - -")


MPI.Init()
comm = MPI.COMM_WORLD
my_rank = MPI.Comm_rank(comm)
root = 0
print("rank $my_rank has $(Threads.nthreads()) threads \n")

g = graph_from_gr(joinpath(@__DIR__, "../test/example_graphs/", graph_name))
order, tw = order_tw_by_dissections_simple(
    g, 
    duration; 
    max_imbalances=max_imbalances , 
    seed=base_seed + my_rank * seed_diff,
    nsample=base_nsample,
    sample_augment=sample_augment
)
MPI.Barrier(comm)

"""returns the better (rank, treewidth) pair"""
function best(order1::Tuple{Int, Int}, order2::Tuple{Int, Int})
    order1[2] < order2[2] ? order1 : order2
end

rank_with_best, best_tw = MPI.Allreduce((my_rank, tw), best, comm)
MPI.Barrier(comm)


if my_rank == root
    best_order = similar(order)
    rreq = MPI.Irecv!(best_order, rank_with_best, rank_with_best, comm)
end

if my_rank == rank_with_best
    print("rank $my_rank sending elimination order to root \n")
    sreq = MPI.Isend(order, root, my_rank, comm)
end

MPI.Barrier(comm)

if my_rank == root
    @show best_tw
    @show best_order
end