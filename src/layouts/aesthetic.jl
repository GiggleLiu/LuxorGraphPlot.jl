using Statistics, Enzyme, Optim

export AestheticLayout

@kwdef struct AestheticLayout <: AbstractLayout
    optimal_distance::Float64 = 50.0
    dimension::Int = 2
end

function render_locs(graph, l::AestheticLayout)
    return aesthetic_layout(graph;
                        optimal_distance=l.optimal_distance,
                        dimension=l.dimension
                    )
end

function aesthetic_layout(g::AbstractGraph; optimal_distance=50.0, dimension=2)
    if nv(g) == 1
        return [zero(Point{dimension, Float64})]
    elseif nv(g) == 2
        return [zero(Point{dimension, Float64}), Point(ntuple(i->i==1 ? Float64(optimal_distance) : 0.0, dimension))]
    end
    locs = [Point(ntuple(_->randn(), dimension)) for _ in 1:nv(g)]
    res = pack_points(Optim.optimize(locs -> loss_aesthetic(g, pack_points(locs)), unpack_points(locs), LBFGS(), Optim.Options(f_abstol=1e-8); autodiff=:forward).minimizer)
    return res .* (2 * optimal_distance)
end

function loss_aesthetic(g::AbstractGraph, locs::Vector{Point{dimension, T}}) where {dimension, T<:Real}
    l1s, l2s = T[], T[]
    for i = 1:nv(g), j = i+1:nv(g)
        push!((has_edge(g, i, j) ? l1s : l2s), distance(locs[i], locs[j]))
    end
    angles = [edge_angle(locs[e.src], locs[e.dst]) for e in edges(g)]
    _mean(x) = isempty(x) ? zero(eltype(x)) : mean(x)
    _std(x) = isempty(x) ? zero(eltype(x)) : std(x)
    l0 = -(_mean(l2s) - _mean(l1s)) * nv(g)
    l1 = (_std(l2s) + _std(l1s)) * nv(g)
    l2 = _mean(inv.(1e-5 .+ abs.(l1s))) + _mean(inv.(1e-5 .+ abs.(l2s)))   # no very close points
    e1 = pseudo_l0_norm(angles)
    e2 = mean(d->pseudo_l0_norm(getindex.(locs, d)), 1:dimension)
    # TDOO: add vertex - edge repulsion term
    return l0 + l1 + l2 + e1 + e2# + e3
end

function edge_angle(p1::Point{2, T}, p2::Point{2, T}) where T
    e1, e2 = normalize(p1), normalize(p2)
    return abs(dot(e1, e2))
end

function pseudo_l0_norm(xs::Vector{T}) where T
    ds = T[]
    for i = 1:length(xs)
        for j = i+1:length(xs)
            push!(ds, abs(xs[i] - xs[j]))
        end
    end
    return norm(ds, 1) / (norm(ds, 2) + T(1e-5))
end

function unpack_points(locs::Vector{Point{dimension, T}}) where {dimension, T}
    return hcat([getindex.(locs, i) for i in 1:dimension]...)
end
function pack_points(locs::Matrix{T}) where T
    return [Point(ntuple(i->locs[j, i], size(locs, 2))) for j in 1:size(locs, 1)]
end