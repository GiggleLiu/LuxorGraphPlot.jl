"""
    spring_layout(g::AbstractGraph;
                       locs=[randn(Point2D{Float64}) for i=1:nv(g)],
                       C=2.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,  # initial moving speed
                       mask::AbstractVector{Bool}=trues(length(locs_x))   # mask for which to relocate
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout(g::AbstractGraph;
                       locs=[randn(Point2D{Float64}) for i=1:nv(g)],
                       C=2.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,
                       mask::AbstractVector{Bool}=trues(length(locs))   # mask for which to relocate
                       )
    @assert nv(g) == length(locs)
    locs = copy(locs)
    adj_matrix = adjacency_matrix(g)

    # The optimal distance bewteen vertices
    k = 1.0

    # Store forces and apply at end of iteration all at once
    force = zero(locs)

    # Iterate niters times
    @inbounds for iter = 1:niters
        # Calculate forces
        for i = 1:nv(g)
            force_i = zero(eltype(locs))
            for j = 1:nv(g)
                i == j && continue
                dist = distance(locs[i], locs[j])

                if !( iszero(adj_matrix[i,j]) && iszero(adj_matrix[j,i]) )
                    # Attractive + repulsive force
                    # F_d = dist² / k - k² / dist # original FR algorithm
                    F_d = dist / k - k^2 / dist^2
                else
                    # Just repulsive
                    # F_d = -k² / dist  # original FR algorithm
                    F_d = -k^2 / dist^2
                end
                force_i += F_d * (locs[j] - locs[i])
            end
            force[i] = force_i
        end
        # Cool down
        temp = α0 / iter
        # Now apply them, but limit to temperature
        for i = 1:nv(g)
            mask[i] || continue
            force_mag  = norm(force[i])
            scale      = min(force_mag, temp) / force_mag
            locs[i] += force[i] * scale
        end
    end

    C .* locs
end


"""
    spring_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                       C=2.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,  # initial moving speed
                       mask::AbstractVector{Bool}=trues(length(locs_x))   # mask for which to relocate
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                       C=2.0,   # the optimal vertex distance
                       niters=100,
                       α0=2.0,
                       aspect_ratio=0.2,
                       mask::AbstractVector{Bool}=trues(length(zlocs))   # mask for which to relocate
                       )
    @assert nv(g) == length(zlocs)
    locs=[randn(Point3D{Float64}) for _=1:nv(g)]
    zlocs = zlocs ./ C
    set_z(p::Point3D{T}, zloc) where T = Point(p[1], p[2], T(zloc))
    locs .= set_z.(locs, zlocs)
    adj_matrix = adjacency_matrix(g)

    # The optimal distance bewteen vertices
    k = 1.0

    # Store forces and apply at end of iteration all at once
    force = zero(locs)

    # Iterate niters times
    @inbounds for iter = 1:niters
        # Calculate forces
        for i = 1:nv(g)
            force_i = zero(eltype(locs))
            for j = 1:nv(g)
                i == j && continue
                dist = distance(locs[i], locs[j])

                if !( iszero(adj_matrix[i,j]) && iszero(adj_matrix[j,i]) )
                    # Attractive + repulsive force
                    # F_d = dist² / k - k² / dist # original FR algorithm
                    F_d = dist / k - k^2 / dist^2
                else
                    # Just repulsive
                    # F_d = -k² / dist  # original FR algorithm
                    F_d = -k^2 / dist^2
                end
                force_i += F_d * (locs[j] - locs[i])
            end
            force[i] = force_i
        end
        # Cool down
        temp = α0 / iter
        # Now apply them, but limit to temperature
        for i = 1:nv(g)
            mask[i] || continue
            force_mag  = norm(force[i])
            scale      = min(force_mag, temp) / force_mag
            locs[i] += force[i] * scale
        end
        # force set z locations
        locs .= set_z.(locs, zlocs)
    end

    # project to x-z plane
    map(loc->Point(loc[1], loc[2]*aspect_ratio + loc[3]) * C, locs)
end

