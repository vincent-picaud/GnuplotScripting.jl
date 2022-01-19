```@meta
CurrentModule = GnuPlotScripting
```

# [Beside `free_form()`](@id beside_free_form)

Some task are recurrent and need to be easily performed. This is the
role of these extra functions. I will extend this in the future. If
you are interested, any contribution is open and welcome :)

## Set plot title

A very basic example

```julia
set_title(gp,"My_plot_title",enhanced=false)
```

is equivalent to 

```julia
free_form(gp, "set title \"My_plot_title\" noenhanced")
```

## Plotting vertical bars

An easy way to plot vertical bars:

```julia
using GnuPlotScripting

gp = GnuPlotScript()

add_vertical_line(gp,-5.0,name="left")
add_vertical_line(gp,+5.0,name="right")

free_form(gp,"plot exp(-x*x/25) with line t 'Gaussian'")

export_png(gp, "vlines.png")
```

![vlines](figures/vlines.png)

See [`add_vertical_line`](@ref).
