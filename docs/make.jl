using GnuPlotScripting
using Documenter

DocMeta.setdocmeta!(GnuPlotScripting, :DocTestSetup, :(using GnuPlotScripting); recursive=true)

makedocs(;
    modules=[GnuPlotScripting],
    authors="Vincent Picaud",
    repo="https://github.com/vincent-picaud/GnuPlotScripting.jl/blob/{commit}{path}#{line}",
    sitename="GnuPlotScripting.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://vincent-picaud.github.io/GnuPlotScripting.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting started" => "getting_started.md",
    ],
)

deploydocs(;
    repo="github.com/vincent-picaud/GnuPlotScripting.jl",
    devbranch="main",
)
