"""
    AbstractLayout

Abstract type for layout algorithms.
"""
abstract type AbstractLayout end

"""
    render_locs(graph, layout::Layout)

Render the vertex locations for a graph from an [`AbstractLayout`](@ref) instance.

### Arguments
* `graph::AbstractGraph`: the graph to render
* `layout::AbstractLayout`: the layout algorithm
"""
function render_locs(graph::AbstractGraph, layout::AbstractVector)
    @assert nv(graph) == length(layout) "The number of vertices in the graph must match the number of locations, got $(nv(graph)) vertices and $(length(layout)) locations"
    return Point.(layout)
end

"""
    Layered <: AbstractLayout

Layered version of a parent layout algorithm.

### Fields
* `parent::LT`: the parent layout algorithm
* `zlocs::Vector{T}`: the z-axis locations
* `aspect_ratio::Float64`: the aspect ratio of the z-axis
"""
struct Layered{LT<:AbstractLayout, T} <: AbstractLayout
    parent::LT
    zlocs::Vector{T}
    aspect_ratio::Float64
end

function render_locs(graph, l::Layered)
    @assert nv(graph) == length(l.zlocs) "The number of vertices in the graph must match the number of z-axis locations, got $(nv(graph)) vertices and $(length(l.zlocs)) z-axis locations"
    locs = render_locs(graph, l.parent)
    map(lz->Point(lz[1][1], lz[1][2]* l.aspect_ratio + lz[2]), zip(locs, l.zlocs))
end

struct LayoutQuality
    closeness::Float64
    mean_distance_deviation::Float64
end

function quality_of_layout(graph, locs, optimal_distance)
    average_distance_con = sum([Layouts.distance(locs[e.src], locs[e.dst]) for e in edges(graph)])/ne(graph)
    average_distance_dis = sum([Layouts.distance(locs[e.src], locs[e.dst]) for e in edges(complement(graph))])
    deviation = abs(average_distance_con - optimal_distance) / min(optimal_distance, average_distance_con)
    return LayoutQuality(average_distance_dis/average_distance_con, deviation)
end

