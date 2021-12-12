export export_png

function export_png(gp::GnuPlotScript,filename::AbstractString)
    _append_to_script(gp,"set terminal push")
    _append_to_script(gp,"set terminal png")

    filename = splitext(filename)
    if length(filename)>1 && filename[2]!=".png"
        @warn "File extension $(filename[2]) replaced by \".png\""
    end
    filename = first(filename)*".png"

    _append_to_script(gp,"set output '$filename'")
    _append_to_script(gp,"replot")
    _append_to_script(gp,"set terminal pop")

    filename
end
