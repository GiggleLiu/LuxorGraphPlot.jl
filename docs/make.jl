using Pkg
using LuxorGraphPlot
using Documenter
using DocThemeIndigo
using Literate

for each in readdir(pkgdir(LuxorGraphPlot, "examples"))
    input_file = pkgdir(LuxorGraphPlot, "examples", each)
    endswith(input_file, ".jl") || continue
    @info "building" input_file
    output_dir = pkgdir(LuxorGraphPlot, "docs", "src", "generated")
    Literate.markdown(input_file, output_dir; name=each[1:end-3], execute=false)
end

indigo = DocThemeIndigo.install(LuxorGraphPlot)
DocMeta.setdocmeta!(LuxorGraphPlot, :DocTestSetup, :(using LuxorGraphPlot); recursive=true)

makedocs(;
    modules=[LuxorGraphPlot],
    authors="Jinguo Liu",
    repo="https://github.com/GiggleLiu/LuxorGraphPlot.jl/blob/{commit}{path}#{line}",
    sitename="LuxorGraphPlot.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://giggleliu.github.io/LuxorGraphPlot.jl",
        assets=String[indigo],
    ),
    pages=[
        "Home" => "index.md",
        "Examples" => [
            "Features" => "generated/features.md",
        ],
        "Topics" => [
            "Gist" => "gist.md",
        ],
        "References" => "ref.md",
    ],
    doctest=false,
    warnonly = :missing_docs,
)

deploydocs(;
    repo="github.com/GiggleLiu/LuxorGraphPlot.jl",
)
