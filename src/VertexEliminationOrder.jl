module VertexEliminationOrder



include("heuristics.jl")
include("flowcutter.jl")
include("dissection.jl")

export minfill!, minwidth!, augment_flow!, forward_grow!, piercing_node, flowcutter!, tree_order!, nested_dissection


end
