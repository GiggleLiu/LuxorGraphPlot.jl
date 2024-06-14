"""
    stressmajorize_layout(g::AbstractGraph;
                               locs=rand_points_2d(nv(g)),
                               w=nothing,
                               optimal_distance=2.0,   # the optimal vertex distance
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
                               optimal_distance=50.0,   # the optimal vertex distance
                               locs=nothing,
                               w=nothing,
                               maxiter = 400 * nv(g)^2,
                               abstols=1e-2,
                               reltols=1e-2,
                               abstolx=1e-2,
                               verbose = false)

    locs = locs === nothing ? rand_points_2d(nv(g)) .* optimal_distance : locs
    δ = optimal_distance .* hcat([gdistances(g, i) for i=1:nv(g)]...)

    if w === nothing
        w = δ .^ -2
        w[.!isfinite.(w)] .= 0
    end

    @assert length(locs)==size(δ, 1)==size(δ, 2)==size(w, 1)==size(w, 2)
    locs = copy(locs)
    Lw = weighted_laplacian(w)
    pinvLw = pinv(Lw)
    newstress = stress(locs, δ, w)
    iter = 0
    L = zeros(eltype(Lw), nv(g), nv(g))
    local locs_new
    for outer iter = 1:maxiter
        lz = LZ!(L, locs, δ, w)
        locs_new = pinvLw * (lz * locs)
        @assert all(isfinite.(locs_new))
        newstress, oldstress = stress(locs_new, δ, w), newstress
        verbose && @info("""Iteration $iter
        Change in coordinates: $(norm(distance.(locs_new, locs)))
        Stress: $newstress (change: $(newstress-oldstress))
        """)
        if abs(newstress - oldstress) < reltols * newstress ||
                abs(newstress - oldstress) < abstols ||
                norm(distance.(locs_new, locs)) < abstolx
            break
        end
        locs = locs_new
    end
    iter == maxiter && @warn("Maximum number of iterations reached without convergence")
    return locs
end

function stressmajorize_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                               w=nothing,
                               optimal_distance=50.0,   # the optimal vertex distance
                               maxiter = 400 * nv(g)^2,
                               abstols=1e-2,
                               reltols=1e-2,
                               abstolx=1e-2,
                               aspect_ratio=0.2,
                               verbose = false)

    @assert length(zlocs)==nv(g) "The number of layers must be equal to the number of vertices in the graph, got: $(length(zlocs)) and $(nv(g))"
    locs=[randn(Point3D{Float64}) for _=1:nv(g)]
    set_z(p::Point3D{T}, zloc) where T = Point(p[1], p[2], T(zloc))
    locs .= set_z.(locs, zlocs)

    δ = optimal_distance .* hcat([gdistances(g, i) for i=1:nv(g)]...)
    if w === nothing
        w = δ .^ -2
        w[.!isfinite.(w)] .= 0
    end

    @assert length(locs)==size(δ, 1)==size(δ, 2)==size(w, 1)==size(w, 2)
    locs = copy(locs)
    Lw = weighted_laplacian(w)
    pinvLw = pinv(Lw)
    newstress = stress(locs, δ, w)
    iter = 0
    L = zeros(eltype(Lw), nv(g), nv(g))
    local locs_new
    for outer iter = 1:maxiter
        lz = LZ!(L, locs, δ, w)
        locs_new = pinvLw * (lz * locs)
        @assert all(isfinite.(locs_new))
        newstress, oldstress = stress(locs_new, δ, w), newstress
        verbose && @info("""Iteration $iter
        Change in coordinates: $(norm(distance.(locs_new, locs)))
        Stress: $newstress (change: $(newstress-oldstress))
        """)
        if abs(newstress - oldstress) < reltols * newstress ||
                abs(newstress - oldstress) < abstols ||
                norm(distance.(locs_new, locs)) < abstolx
            break
        end
        locs = set_z.(locs_new, zlocs)
    end
    iter == maxiter && @warn("Maximum number of iterations reached without convergence")
    # project to x-z plane
    map(loc->Point(loc[1], loc[2]*aspect_ratio + loc[3]), locs)
end


function stress(locs::AbstractVector{Point{D, T}}, d, w) where {D, T}
    s = 0.0
    n = length(locs)
    @assert n==size(d, 1)==size(d, 2)==size(w, 1)==size(w, 2)
    @inbounds for j=1:n, i=1:j-1
        s += w[i, j] * (distance(locs[i], locs[j]) - d[i,j])^2
    end
    return s
end

function weighted_laplacian(w::AbstractMatrix{T}) where T
    n = LinearAlgebra.checksquare(w)
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

function LZ!(L::AbstractMatrix{T}, locs::AbstractVector{Point{D, T2}}, d, w) where {D, T, T2}
    @assert length(locs)==size(d, 1)==size(d, 2)==size(w, 1)==size(w, 2)
    fill!(L, zero(T))
    n = length(locs)
    @inbounds for i=1:n-1
        diag = zero(T)
        for j=i+1:n
            nrmz = distance(locs[i], locs[j])
            δ = w[i, j] * d[i, j]
            lij = -δ/max(nrmz, 1e-8)
            L[i, j] = lij
            diag -= lij
        end
        L[i, i] += diag
    end
    @inbounds for i=2:n
        diag = zero(T)
        for j=1:i-1
            lij = L[j,i]
            L[i,j] = lij
            diag -= lij
        end
        L[i,i] += diag
    end
    return L
end

