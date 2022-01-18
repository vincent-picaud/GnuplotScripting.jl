using Documenter
using GnuPlotScripting

makedocs(
    sitename = "GnuPlotScripting.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "API" => "api.md"
    ]
)

deploydocs(
    repo = "github.com/bjack205/GnuPlotScripting.jl.git",
    devbranch = "main"
)
