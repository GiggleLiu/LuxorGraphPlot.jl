"""
    spectral_layout(g::AbstractGraph, weight=nothing)

Spectral layout for graph plotting, returns a vector of vertex locations.
"""
function spectral_layout(g::AbstractGraph, weight=nothing; C=2.0)
    if nv(g) == 1
        return [0.0], [0.0]
    elseif nv(g) == 2
        return [0.0, C], [0.0, 0.0]
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
        return _spectral(A) .* 2C
    else
        L = laplacian_matrix(g)
        return _spectral(Matrix(L)) .* 2C
    end
end

function _spectral(L::Matrix)
    eigenvalues, eigenvectors = eigen(L)
    index = sortperm(eigenvalues)[2:3]
    return eigenvectors[:, index[1]], eigenvectors[:, index[2]]
end

function _spectral(A)
    data = vec(sum(A, dims=1))
    D = Graphs.sparse(Base.OneTo(length(data)), Base.OneTo(length(data)), data)
    L = D - A
    eigenvalues, eigenvectors = Graphs.LinAlg.eigs(L, nev=3, which=Graphs.SR())
    index = sortperm(real(eigenvalues))[2:3]
    return real(eigenvectors[:, index[1]]), real(eigenvectors[:, index[2]])
end
