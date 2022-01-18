```@meta
CurrentModule = GnuPlotScripting
```

# Getting started

## A 2D plot example

```julia
using GnuPlotScripting 

X = -2:0.1:2
Y = -2:0.1:2
M = [exp(-x_i*x_i-y_j*y_j) for x_i=X, y_j=Y]

gp = GnuPlotScript()

id = register_data(gp, M)

free_form(gp,"set autoscale fix")
free_form(gp,"plot '$id' matrix using 1:2:3 with image")

export_png(gp, figfile("2D.png"))
```

![script_2](./figures/2D.png)

