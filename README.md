# VertexEliminationOrder

A Julia package to find a vertex elimination order which gives an upper bound of the treewidth of a graph.

## Heuristics functions

You can use the heuristics function like minwidth! or minfill! like this:

```jlrepl
julia> G = smallgraph("house")

julia> minfill!(G)
([5, 1, 4, 3, 2], 2)
```

```jlrepl
julia> G = smallgraph("house")

julia> minwidth!(G)
([1, 5, 4, 3, 2], 2)
```

These functions return you a vertex elimination order and the treewidth associated. For the moment there is no wrapper for sampling those functions several times and return the best order i.e the one which leads to the lowest treewidth.

## Flow-Cutter Algorithm

There is an implementation, not perfect, of the flowcutter algorithm described in depth [here](https://arxiv.org/pdf/1504.03812.pdf). You can use the wrappers function to make this algorithm computes vertex elimination order several times and get the best order. 

### MPI flow-cutter wrapper

To use the MPI version of the wrapper function of flow-cutter make sure to have an implementation of mpi installed on your machine, on ubuntu for instance: `sudo apt install openmpi-bin`

Then in Julia set the environment variable to make MPI.jl use the system mpi and not install its own. Then add the package MPI.jl and build it like so:
```jlrepl
julia> ENV["JULIA_MPI_BINARY"]="system"

julia>]add MPI

julia>]build MPI
```

Once this is ready you can run the mpi script in `bin` with
`mpiexec -n 2 julia --threads 4 --project=.. mpiwrapper.jl --time 20 --seed 457 --max_imbalances 1.0 0.8 0.7`. This example shows you some of the parameters you can modify.


