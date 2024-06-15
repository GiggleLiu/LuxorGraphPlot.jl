"""
    SpectralLayout <: AbstractLayout

A layout algorithm based on spectral graph theory.

### Fields
* `optimal_distance::Float64`: the optimal distance between vertices
* `dimension::Int`: the number of dimensions
"""
@kwdef struct SpectralLayout <: AbstractLayout
    optimal_distance::Float64 = 50.0
    dimension::Int = 2
end

function render_locs(graph, l::SpectralLayout)
    return spectral_layout(graph;
                        optimal_distance=l.optimal_distance,
                        dimension=l.dimension
                    )
end

"""
    spectral_layout(g::AbstractGraph, weight=nothing; optimal_distance=50.0)

Spectral layout for graph plotting, returns a vector of vertex locations.
"""
function spectral_layout(g::AbstractGraph, weight=nothing; optimal_distance=50.0, dimension=2)
    if nv(g) == 1
        return [zero(Point{dimension, Float64})]
    elseif nv(g) == 2
        return [zero(Point{dimension, Float64}), Point(ntuple(i->i==1 ? Float64(optimal_distance) : 0.0, dimension))]
    end

    if weight === nothing
        weight = ones(ne(g))
    end
    if nv(g) > 500
        A = Graphs.sparse(Int[src(e) for e in edges(g)],
                   Int[dst(e) for e in edges(g)],
                   weight, nv(g), nv(g))
        if is_directed(g)
            A = A + transpose(A)
        end
        return _spectral(A, dimension) .* 16optimal_distance
    else
        L = laplacian_matrix(g)
        return _spectral(Matrix(L), dimension) .* 16optimal_distance
    end
end

function _spectral(L::Matrix, dimension)
    eigenvalues, eigenvectors = eigen(L)
    index = sortperm(eigenvalues)[2:1+dimension]
    return Point.([eigenvectors[:, idx] for idx in index]...)
end

function _spectral(A, dimension)
    data = vec(sum(A, dims=1))
    D = Graphs.sparse(Base.OneTo(length(data)), Base.OneTo(length(data)), data)
    L = D - A
    eigenvalues, eigenvectors = Graphs.LinAlg.eigs(L, nev=3, which=Graphs.SR())
    index = sortperm(real(eigenvalues))[2:1+dimension]
    return Point.([real.(eigenvectors[:, idx]) for idx in index]...)
end
