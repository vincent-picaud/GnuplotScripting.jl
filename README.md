
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://vincent-picaud.github.io/GnuPlotScripting.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://vincent-picaud.github.io/GnuPlotScripting.jl/dev)
[![Build Status](https://github.com/vincent-picaud/GnuPlotScripting.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/vincent-picaud/GnuPlotScripting.jl/actions/workflows/CI.yml?query=branch%3Amain)

# GnuPlotScripting.jl

An **easy to use** and **simple** `gnuplot` wrapping that allows you
to:

- perform direct rendering of Gnuplot plots from Julia,
- create and save Gnuplot scripts with embedded data,
- easily export Gnuplot figures.

```julia
using GnuPlotScripting

# create a gnuplot script
#
gp = GnuPlotScript()

# Fake data
#
X=[-pi:0.1:pi;];
Ys =sin.(X);
Yc =cos.(X);

# embed data into the script
#
id=register_data(gp,hcat(X,Ys,Yc))

# usual gnuplot command
#
free_form(gp,"replot '$id' u 1:3 w l t 'cos'")
free_form(gp,"replot '$id' u 1:2 w l t 'sin'")

# png export of the fig
#
export_png("fig.png",gp)

# write gnuplot script
#
write_script("gnuplot_script.gp",gp)
```
That's it!

After running the previous code you will get a nearly immediate plot
of your figure, a `fig.png` image file

![image](docs/src/figures/trig.png)

and a gnuplot script `gnuplot_script.gp` with embedded data you can
rerun when you want.
