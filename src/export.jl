export export_png


function _nop_yes_no(flag::Union{Nothing,Bool},yes_no::Tuple{AbstractString,AbstractString})
    if flag !== nothing
        if flag
            return first(yes_no)
        else
            return last(yes_no)
        end
    end
    ""
end

function _enhanced(flag::Union{Nothing,Bool})
    _nop_yes_no(flag,("enhanced","noenhanced"))
end                             

# ================================================================


function export_png(gp::GnuPlotScript,filename::AbstractString;
                    enhanced::Union{Nothing,Bool}=nothing)

    # add .png ext to filename
    #
    filename = splitext(filename)
    if length(filename)>1 && filename[2]!=".png"
        @warn "File extension $(filename[2]) replaced by \".png\""
    end
    filename = first(filename)*".png"

    # command
    #
    command = ""
    command *= "set terminal push\n"
    command *= "set terminal png\n"

    command *= _enhanced(enhanced) * "\n"
    
    command *= "set output '$filename'\n"
    command *= "replot\n"
    command *= "set terminal pop\n"

    # append gnuplot instructions
    #
    _append_to_script(gp,command)

    filename
end
