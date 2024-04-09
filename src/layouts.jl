"""
    spring_layout(g::AbstractGraph;
                       locs_x=2*rand(nv(g)).-1.0,
                       locs_y=2*rand(nv(g)).-1.0,
                       C=2.0,   # the optimal vertex distance
                       MAXITER=100,
                       INITTEMP=2.0,
                       mask::AbstractVector{Bool}=trues(length(locs_x))   # mask for which to relocate
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout(g::AbstractGraph;
                       locs_x=2*rand(nv(g)).-1.0,
                       locs_y=2*rand(nv(g)).-1.0,
                       C=2.0,   # the optimal vertex distance
                       MAXITER=100,
                       INITTEMP=2.0,
                       mask::AbstractVector{Bool}=trues(length(locs_x))   # mask for which to relocate
                       )

    locs_x, locs_y = copy(locs_x), copy(locs_y)
    nvg = nv(g)
    adj_matrix = adjacency_matrix(g)

    # The optimal distance bewteen vertices
    k = C * sqrt(4.0 / nvg)
    k² = k * k

    # Store forces and apply at end of iteration all at once
    force_x = zeros(nvg)
    force_y = zeros(nvg)

    # Iterate MAXITER times
    @inbounds for iter = 1:MAXITER
        # Calculate forces
        for i = 1:nvg
            force_vec_x = 0.0
            force_vec_y = 0.0
            for j = 1:nvg
                i == j && continue
                d_x = locs_x[j] - locs_x[i]
                d_y = locs_y[j] - locs_y[i]
                dist²  = (d_x * d_x) + (d_y * d_y)
                dist = sqrt(dist²)

                if !( iszero(adj_matrix[i,j]) && iszero(adj_matrix[j,i]) )
                    # Attractive + repulsive force
                    # F_d = dist² / k - k² / dist # original FR algorithm
                    F_d = dist / k - k² / dist²
                else
                    # Just repulsive
                    # F_d = -k² / dist  # original FR algorithm
                    F_d = -k² / dist²
                end
                force_vec_x += F_d*d_x
                force_vec_y += F_d*d_y
            end
            force_x[i] = force_vec_x
            force_y[i] = force_vec_y
        end
        # Cool down
        temp = INITTEMP / iter
        # Now apply them, but limit to temperature
        for i = 1:nvg
            mask[i] || continue
            fx = force_x[i]
            fy = force_y[i]
            force_mag  = sqrt((fx * fx) + (fy * fy))
            scale      = min(force_mag, temp) / force_mag
            locs_x[i] += force_x[i] * scale
            locs_y[i] += force_y[i] * scale
        end
    end

    locs_x, locs_y
end

"""
    stressmajorize_layout(g::AbstractGraph;
                               locs_x=2*rand(nv(g)) .- 1.0,
                               locs_y=2*rand(nv(g)) .- 1.0,
                               w=nothing,
                               C=2.0,   # the optimal vertex distance
                               maxiter = 400 * nv(g)^2,
                               abstols=1e-2,
                               reltols=1e-2,
                               abstolx=1e-2,
                               verbose = false
                               )

Stress majorization layout for graph plotting, returns a vector of vertex locations.

### References
* https://github.com/JuliaGraphs/GraphPlot.jl/blob/e97063729fd9047c4482070870e17ed1d95a3211/src/stress.jl
"""
function stressmajorize_layout(g::AbstractGraph;
                               locs_x=2*rand(nv(g)) .- 1.0,
                               locs_y=2*rand(nv(g)) .- 1.0,
                               w=nothing,
                               C=2.0,   # the optimal vertex distance
                               maxiter = 400 * nv(g)^2,
                               abstols=1e-2,
                               reltols=1e-2,
                               abstolx=1e-2,
                               verbose = false)

    #δ = fill(1.0, nv(g), nv(g))
    δ = C .* hcat([gdistances(g, i) for i=1:nv(g)]...)
    X0 = hcat(locs_x, locs_y)

    if w === nothing
        w = δ .^ -2
        w[.!isfinite.(w)] .= 0
    end

    @assert size(X0, 1)==size(δ, 1)==size(δ, 2)==size(w, 1)==size(w, 2)
    Lw = weightedlaplacian(w)
    pinvLw = pinv(Lw)
    newstress = stress(X0, δ, w)
    iter = 0
    L = zeros(nv(g), nv(g))
    local X
    for outer iter = 1:maxiter
        #TODO the faster way is to drop the first row and col from the iteration
        X = pinvLw * (LZ!(L, X0, δ, w)*X0)
        @assert all(isfinite.(X))
        newstress, oldstress = stress(X, δ, w), newstress
        verbose && @info("""Iteration $iter
        Change in coordinates: $(norm(X - X0))
        Stress: $newstress (change: $(newstress-oldstress))
        """)
        if abs(newstress - oldstress) < reltols * newstress ||
                abs(newstress - oldstress) < abstols ||
                norm(X - X0) < abstolx
            break
        end
        X0 = X
    end
    iter == maxiter && @warn("Maximum number of iterations reached without convergence")
    return X[:,1], X[:,2]
end

function stress(X, d, w)
    s = 0.0
    n = size(X, 1)
    @assert n==size(d, 1)==size(d, 2)==size(w, 1)==size(w, 2)
    @inbounds for j=1:n, i=1:j-1
        s += w[i, j] * (sqrt(sum(k->abs2(X[i,k] - X[j,k]), 1:size(X,2))) - d[i,j])^2
    end
    @assert isfinite(s)
    return s
end

function weightedlaplacian(w)
    n = LinearAlgebra.checksquare(w)
    T = eltype(w)
    Lw = zeros(T, n, n)
    for i=1:n
        D = zero(T)
        for j=1:n
            i==j && continue
            Lw[i, j] = -w[i, j]
            D += w[i, j]
        end
        Lw[i, i] = D
    end
    return Lw
end

function LZ!(L, Z, d, w)
    fill!(L, zero(eltype(L)))
    n = size(Z, 1)
    @inbounds for i=1:n-1
        D = 0.0
        for j=i+1:n
            nrmz = sqrt(sum(k->abs2(Z[i,k] - Z[j,k]), 1:size(Z,2)))
            δ = w[i, j] * d[i, j]
            lij = -δ/max(nrmz, 1e-8)
            L[i, j] = lij
            D -= lij
        end
        L[i, i] += D
    end
    @inbounds for i=2:n
        D = 0.0
        for j=1:i-1
            lij = L[j,i]
            L[i,j] = lij
            D -= lij
        end
        L[i,i] += D
    end
    return L
end

"""
    spectral_layout(g::AbstractGraph, weight=nothing)

Spectral layout for graph plotting, returns a vector of vertex locations.
"""
function spectral_layout(g::AbstractGraph, weight=nothing)
    if nv(g) == 1
        return [0.0], [0.0]
    elseif nv(g) == 2
        return [0.0, 1.0], [0.0, 0.0]
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
        return _spectral(A)
    else
        L = laplacian_matrix(g)
        return _spectral(Matrix(L))
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

