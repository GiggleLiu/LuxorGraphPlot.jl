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

