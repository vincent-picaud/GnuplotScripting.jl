```@meta
CurrentModule = GnuPlotScripting
```

# The GnuPlotScripting.jl package

This package aim is to easily generate gnuplot plots from Julia. It
allows to:

    - to perform direct rendering of Gnuplot plots from Julia
    - to create and save Gnuplot scripts (possibly with embedded data)
    - to easily export Gnuplot figures

This is a lightweight solution that allows you to quickly visualize
some data.

```@example session
using GnuPlotScripting

gp = GnuPlotScript(direct_plot=false)
free_form(gp,"set terminal png") # hide
free_form(gp,"set output 'sin.png'") # hide

X=[-pi:0.1:pi;];
Ys = sin.(X);
Yc = cos.(X);

id=register_data(gp,hcat(X,Ys,Yc))
free_form(gp,"replot '$id' u 1:3 w l t 'cos'")
free_form(gp,"replot '$id' u 1:2 w l t 'sin'")

write_script("test.gp", gp) # hide
run(Cmd([GnuPlotScripting.gnuplot_exe, "-c", "test.gp"])) # hide
```

![image info](sin.png)


# API

## Index 

```@index
```

## Documentation

```@autodocs
Modules = [GnuPlotScripting]
```
