module Layouts

using LinearAlgebra, Graphs

include("point.jl")
include("spring.jl")
include("stress.jl")
include("spectral.jl")

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

end