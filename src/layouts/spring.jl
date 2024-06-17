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
    α0::Float64 = 2*optimal_distance  # initial moving speed
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
    spring_layout(g::AbstractGraph;
                       locs=nothing,
                       optimal_distance=50.0,   # the optimal vertex distance
                       maxiter=100,
                       α0=2*optimal_distance,  # initial moving speed
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
                       α0=2*optimal_distance,
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

"""
    LayeredSpringLayout(; zlocs, optimal_distance, aspect_ration=0.2)

Create a layered spring layout.

### Keyword Arguments
* `zlocs`: the z-axis locations
* `optimal_distance::Float64`: the optimal distance between vertices
* `aspect_ration::Float64`: the aspect ratio of the z-axis
* `α0::Float64`: the initial moving speed
* `maxiter::Int`: the maximum number of iterations
"""
function LayeredSpringLayout(; zlocs, optimal_distance=50.0, aspect_ratio=0.2, α0=2*optimal_distance, maxiter=100)
    return Layered(SpringLayout(; optimal_distance, α0, maxiter), zlocs, aspect_ratio)
end
