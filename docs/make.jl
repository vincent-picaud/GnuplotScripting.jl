#
# CAVEAT: src/all_plots.jl generates all plots and save them into the scr/figures/ dir.
#
using GnuplotScripting
using Documenter

DocMeta.setdocmeta!(GnuplotScripting, :DocTestSetup, :(using GnuplotScripting); recursive=true)

makedocs(;
    modules=[GnuplotScripting],
    authors="Vincent Picaud",
    repo="https://github.com/vincent-picaud/GnuplotScripting.jl/blob/{commit}{path}#{line}",
    sitename="GnuplotScripting.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://vincent-picaud.github.io/GnuplotScripting.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "New things to learn" => "new_things_to_learn.md",
        "Beside `free_form()`" => "beside_free_form.md",
        "API" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/vincent-picaud/GnuplotScripting.jl",
    devbranch="main",
)
