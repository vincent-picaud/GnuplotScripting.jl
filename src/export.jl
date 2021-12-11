export export_png

function export_png(gp::GnuPlotScript,filename::AbstractString)
    free_form(gp,"set terminal push")
    free_form(gp,"set terminal png")
    filename = first(split(filename))*".png"
    free_form(gp,"set output '$filename'")
    free_form(gp,"replot")
    free_form(gp,"set terminal pop")
end
