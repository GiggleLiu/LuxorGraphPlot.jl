"""
    SpringLayout <: AbstractLayout

A layout algorithm based on a spring model.

### Fields
* `optimal_distance::Float64`: the optimal distance between vertices
* `maxiter::Int`: the maximum number of iterations
* `α0::Float64`: the initial moving speed
* `meta::Dict{Symbol, Any}`: graph dependent meta information, including
    * `initial_locs`: initial vertex locations
    * `mask`: boolean mask for which vertices to relocate
"""
@kwdef struct SpringLayout <: AbstractLayout
    optimal_distance::Float64 = 50.0
    maxiter::Int = 100
    α0::Float64 = 2.0  # initial moving speed
    meta::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

function render_locs(graph, l::SpringLayout)
    return spring_layout(graph;
                        optimal_distance=l.optimal_distance,
                        maxiter=l.maxiter,
                        α0=l.α0,
                        locs=get(l.meta, :initial_locs, nothing),
                        mask=get(l.meta, :mask, nothing),
                    )
end

"""
    LayeredSpringLayout <: AbstractLayout

A layout algorithm based on a spring model for layered graphs.

### Fields
* `zlocs::Vector{T}`: the z-axis locations
* `optimal_distance::Float64`: the optimal distance between vertices
* `maxiter::Int`: the maximum number of iterations
* `α0::Float64`: the initial moving speed
* `aspect_ratio::Float64`: the aspect ratio of the z-axis
"""
@kwdef struct LayeredSpringLayout{T} <: AbstractLayout
    zlocs::Vector{T}
    optimal_distance::Float64 = 50.0
    maxiter::Int = 100
    α0::Float64 = 2.0
    aspect_ratio::Float64 = 0.2
end

function render_locs(graph, l::LayeredSpringLayout)
    return spring_layout_layered(graph, l.zlocs;
                        optimal_distance=l.optimal_distance,
                        maxiter=l.maxiter,
                        α0=l.α0,
                        aspect_ratio=l.aspect_ratio,
                    )
end

"""
    spring_layout(g::AbstractGraph;
                       locs=nothing,
                       optimal_distance=50.0,   # the optimal vertex distance
                       maxiter=100,
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
                       maxiter=100,
                       α0=2.0,
                       mask=nothing,
                       )
    locs = locs === nothing ? rand_points_2d(nv(g)) : Point.(locs) ./ optimal_distance
    mask = mask === nothing ? trues(nv(g)) : mask
    @assert nv(g) == length(locs) "number of vertices in graph and locs must be the same, got $(nv(g)) and $(length(locs))"

    # Store forces and apply at end of iteration all at once
    force = zero(locs)

    # Iterate maxiter times
    @inbounds for iter = 1:maxiter
        # Cool down
        temp = α0 / iter
        spring_step!(g, locs, force; optimal_distance=1.0, temp, mask)
    end

    optimal_distance .* locs
end


"""
    spring_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                       optimal_distance=50.0,   # the optimal vertex distance
                       maxiter=100,
                       α0=2.0,  # initial moving speed
                       aspect_ratio=0.2,
                       )

Spring layout for graph plotting, returns a vector of vertex locations.

!!! note
    This function is copied from [`GraphPlot.jl`](https://github.com/JuliaGraphs/GraphPlot.jl),
    where you can find more information about his function.
"""
function spring_layout_layered(g::AbstractGraph, zlocs::AbstractVector;
                       optimal_distance=50.0,   # the optimal vertex distance
                       maxiter=100,
                       α0=2.0,
                       aspect_ratio=0.2,
                       )
    @assert nv(g) == length(zlocs) "number of vertices in graph and zlocs must be the same, got $(nv(g)) and $(length(zlocs))"
    locs=[randn(Point3D{Float64}) for _=1:nv(g)]
    zlocs = zlocs ./ optimal_distance
    set_z(p::Point3D{T}, zloc) where T = Point(p[1], p[2], T(zloc))
    locs .= set_z.(locs, zlocs)
    mask=trues(length(zlocs))   # mask for which to relocate

    # Store forces and apply at end of iteration all at once
    force = zero(locs)

    # Iterate maxiter times
    @inbounds for iter = 1:maxiter
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


