export export_png

function export_png(gp::GnuPlotScript,filename::AbstractString)
    _append_to_script(gp,"set terminal push")
    _append_to_script(gp,"set terminal png")
    filename = first(split(filename))*".png"
    _append_to_script(gp,"set output '$filename'")
    _append_to_script(gp,"replot")
    _append_to_script(gp,"set terminal pop")
end
