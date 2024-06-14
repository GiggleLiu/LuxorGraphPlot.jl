"""
    spring_layout(g::AbstractGraph;
                       locs=nothing,
                       optimal_distance=50.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,  # initial moving speed
                       mask::AbstractVector{Bool}=trues(nv(g))   # mask for which to relocate
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout(g::AbstractGraph;
                       locs=nothing,
                       optimal_distance=50.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,
                       mask::AbstractVector{Bool}=trues(nv(g))   # mask for which to relocate
                       )
    locs = locs === nothing ? rand_points_2d(nv(g)) : locs ./ optimal_distance
    @assert nv(g) == length(locs)

    # Store forces and apply at end of iteration all at once
    force = zero(locs)

    # Iterate niters times
    @inbounds for iter = 1:niters
        # Cool down
        temp = α0 / iter
        spring_step!(g, locs, force; optimal_distance=1.0, temp, mask)
    end

    optimal_distance .* locs
end


"""
    spring_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                       optimal_distance=50.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,  # initial moving speed
                       mask::AbstractVector{Bool}=trues(length(zlocs))   # mask for which to relocate
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                       optimal_distance=50.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,
                       aspect_ratio=0.2,
                       mask::AbstractVector{Bool}=trues(length(zlocs))   # mask for which to relocate
                       )
    @assert nv(g) == length(zlocs)
    locs=[randn(Point3D{Float64}) for _=1:nv(g)]
    zlocs = zlocs ./ optimal_distance
    set_z(p::Point3D{T}, zloc) where T = Point(p[1], p[2], T(zloc))
    locs .= set_z.(locs, zlocs)

    # Store forces and apply at end of iteration all at once
    force = zero(locs)

    # Iterate niters times
    @inbounds for iter = 1:niters
        # Cool down
        temp = α0 / iter
        spring_step!(g, locs, force; optimal_distance=1.0, temp, mask)
        # force set z locations
        locs .= set_z.(locs, zlocs)
    end

    # project to x-z plane
    map(loc->Point(loc[1], loc[2]*aspect_ratio + loc[3]) * optimal_distance, locs)
end

function spring_step!(g::AbstractGraph, locs, force;
                       optimal_distance, temp, mask)
    # Calculate forces
    for i = 1:nv(g)
        force_i = zero(eltype(locs))
        for j = 1:nv(g)
            i == j && continue
            dist = distance(locs[i], locs[j])

            if has_edge(g, i, j)
                # Attractive + repulsive force
                # F_d = dist² / k - k² / dist # original FR algorithm
                F_d = dist / optimal_distance - optimal_distance^2 / dist^2
            else
                # Just repulsive
                # F_d = -k² / dist  # original FR algorithm
                F_d = -optimal_distance^2 / dist^2
            end
            force_i += F_d * (locs[j] - locs[i])
        end
        force[i] = force_i
    end
    # Now apply them, but limit to temperature
    for i = 1:nv(g)
        mask[i] || continue
        force_mag  = norm(force[i])
        scale      = min(force_mag, temp) / force_mag
        locs[i] += force[i] * scale
    end
end


