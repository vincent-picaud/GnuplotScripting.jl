```@meta
CurrentModule = GnuPlotScripting
```

# GnuPlotScripting

Documentation for [GnuPlotScripting](https://github.com/vincent-picaud/GnuPlotScripting.jl).

You first plot, using the usual gnuplot commands:

```@example session
using GnuPlotScripting

gp = GnuPlotScript(direct_plot = false)

X=[-pi:0.1:pi;];
Ys = sin.(X);
Yc = cos.(X);

id=register_data(gp,hcat(X,Ys,Yc))
free_form(gp,"replot '$id' u 1:3 w l t 'cos'")
free_form(gp,"replot '$id' u 1:2 w l t 'sin'")

export_png(gp, "sin.png") 

write_script("test.gp", gp) # hide
run(Cmd([GnuPlotScripting.gnuplot_exe, "test.gp"])) # hide
nothing # hide
```

![image info](sin.png)



```@index
```

```@autodocs
Modules = [GnuPlotScripting]
```
