```@meta
CurrentModule = LuxorGraphPlot
```

# LuxorGraphPlot

## Features
1. automatically detecting the size of the diagram by combining [`nodestore`](@ref) and [`with_nodes`](@ref).
2. connecting nodes with edges, finding middle points and corners of the nodes. Related APIs: `Luxor.midpoint`, [`left`](@ref), [`right`](@ref), [`top`](@ref), [`bottom`](@ref), [`center`](@ref), [`boundary`](@ref).
3. simple graph layouts, such as [`SpringLayout`](@ref), [`StressLayout`](@ref), [`SpectralLayout`](@ref), [`LayeredSpringLayout`](@ref) and [`LayeredStressLayout`](@ref).