module VertexEliminationOrder

using LightGraphs
using DataStructures
using StatsBase
using Parameters
using SparseArrays

include("utils.jl")
export treewidth_by_elimination!, tree_order!, graph_from_gr, square_lattice_graph
include("heuristics.jl")
export minfill!, minwidth!
include("flowcutter.jl")
export augment_flow!, forward_grow!, piercing_node, flowcutter!
include("dissection.jl")
export iterative_dissection


end
