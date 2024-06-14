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

