"""
    Point{D, T}

A point in D-dimensional space, with coordinates of type T.
"""
struct Point{D, T <: Real}
    data::NTuple{D, T}
end
const Point2D{T} = Point{2, T}
const Point3D{T} = Point{3, T}
dimension(::Point{D}) where D = D
Base.eltype(::Type{Point{D, T}}) where {D, T} = T
Point(x::Real...) = Point((x...,))
LinearAlgebra.dot(x::Point, y::Point) = mapreduce(*, +, x.data .* y.data)
LinearAlgebra.norm(x::Point) = sqrt(sum(abs2, x.data))
Base.:*(x::Real, y::Point) = Point(x .* y.data)
Base.:*(x::Point, y::Real) = Point(x.data .* y)
Base.:/(y::Point, x::Real) = Point(y.data ./ x)
Base.:+(x::Point, y::Point) = Point(x.data .+ y.data)
Base.:-(x::Point, y::Point) = Point(x.data .- y.data)
Base.isapprox(x::Point, y::Point; kwargs...) = all(isapprox.(x.data, y.data; kwargs...))
Base.getindex(p::Point, i::Int) = p.data[i]
Base.broadcastable(p::Point) = p.data
Base.iterate(p::Point, args...) = iterate(p.data, args...)
Base.zero(::Type{Point{D, T}}) where {D, T} = Point(ntuple(i->zero(T), D))
Base.zero(::Point{D, T}) where {D, T} = Point(ntuple(i->zero(T), D))
distance(p::Point, q::Point) = norm(p - q)
Base.rand(::Type{Point{D, T}}) where {D, T} = Point(ntuple(_->rand(T), D))
Base.randn(::Type{Point{D, T}}) where {D, T} = Point(ntuple(_->randn(T), D))
Base.isfinite(p::Point) = all(isfinite, p.data)
rand_points_2d(n::Int) = [Point(randn(), randn()) for _ in 1:n]