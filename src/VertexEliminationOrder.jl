module VertexEliminationOrder

using LightGraphs
using DataStructures
using StatsBase
using Parameters
using SparseArrays

include("utils.jl")
include("heuristics.jl")
include("flowcutter.jl")
include("dissection.jl")

export minfill!, minwidth!, augment_flow!, forward_grow!, piercing_node, flowcutter!, tree_order!, iterative_dissection!, treewidth_by_elimination!


end
