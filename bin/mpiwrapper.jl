using MPI 
ENV["JULIA_MPI_BINARY"]="system"
using VertexEliminationOrder

graph_name = "sycamore_53_20.gr"
duration = 30

MPI.Init()
comm = MPI.COMM_WORLD
my_rank = MPI.Comm_rank(comm)
root = 0
print("rank $my_rank has $(Threads.nthreads()) threads \n")

g = graph_from_gr(joinpath(@__DIR__, "../test/example_graphs/", graph_name))
order, tw = order_tw_by_dissections_simple(g, duration, [1.0, 0.8, 0.6], 42 + my_rank * 1000)
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