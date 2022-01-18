# I had some problems to generate plot during CI: here is a script to
# generate them before committing...  This is ugly and not scalable,
# but for the moment this is the only solution I found.
#

using GnuPlotScripting          
figdir = joinpath(@__DIR__,"figures")
figfile(f::AbstractString)=joinpath(figdir,f)

# Script 1
#
gp = GnuPlotScript()

X=[-pi:0.1:pi;];
Ys =sin.(X);
Yc =cos.(X);

id=register_data(gp,hcat(X,Ys,Yc))
free_form(gp,"replot '$id' u 1:3 w l t 'cos'")
free_form(gp,"replot '$id' u 1:2 w l t 'sin'")

export_png(gp, figfile("trig.png"))

# Script 2
#
X = -2:0.1:2
Y = -2:0.1:2
M = [exp(-x_i*x_i-y_j*y_j) for x_i=X, y_j=Y]

gp = GnuPlotScript()

id = register_data(gp, M)

free_form(gp,"set autoscale fix")
free_form(gp,"plot '$id' matrix using 1:2:3 with image")

export_png(gp, figfile("2D.png"))
