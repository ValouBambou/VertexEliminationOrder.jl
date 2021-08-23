using MPI 
ENV["JULIA_MPI_BINARY"]="system"
using VertexEliminationOrder
using ArgParse


function parse_commandline(ARGS)
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--seed"
            help = "Base seed to use for sampling flow-cutter inputs."
            default = 42
            arg_type = Int64
        "--seed_bound"
            help = "Minimum difference of seed between MPI processes."
            default = 1000
            arg_type = Int64
        "--time"
            help = "The number of seconds to run flow cutter for."
            default = 30
            arg_type = Int64
        "--graph"
            help = "The name of the graph file .gr to open."
            default = "sycamore_53_20.gr"
            arg_type = String
        "--dir_graphfiles"
            help = "Path to your graph files .gr to read them."
            default = "$(@__DIR__)/../test/example_graphs/"
            arg_type = String
        "--nsample"
            help = "The number of sample of flow cutter random inputs per execution."
            default = 20
            arg_type = Int64
            
        "--sample_augment"
            help = "The number of execution needed before increasing nsample."
            default = 8
            arg_type = Int64
        "--max_imbalances"
            nargs ='*'
            help = "The max imabalances to select best cut from flow-cutter."
            default = [1.0, 0.8, 0.6]
            arg_type = Float64
    end

    return parse_args(ARGS, s)
end

parsed_args = parse_commandline(ARGS)

graph_name = parsed_args["graph"]
dirgraphfiles = parsed_args["dir_graphfiles"]
duration = parsed_args["time"]
max_imbalances = parsed_args["max_imbalances"]
base_seed = parsed_args["seed"]
seed_diff = parsed_args["seed_bound"]
base_nsample = parsed_args["nsample"]
sample_augment = parsed_args["sample_augment"]

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

g = graph_from_gr(joinpath(dirgraphfiles, graph_name))
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