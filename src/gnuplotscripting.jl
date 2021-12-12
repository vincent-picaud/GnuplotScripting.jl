export GnuPlotScript
export register_data
export free_form
export plot, replot
export set_title
export add_vertical_line
export write_script

using DelimitedFiles

# By now we directly use hash() as data_id. However, this will maybe change in
# the future, that's why we declare dedicated type.
#
const RegisteredData_UUID = typeof(hash(1))

# Gnuplot exe
# TODO: windows!
#
@static if Sys.iswindows()
    const gnuplot_exe = "gnuplot.exe"
else
    const gnuplot_exe = "gnuplot"
end


# convert data id to gnuplot id
#
to_gnuplot_uuid(uuid::RegisteredData_UUID) = "\$G"*string(uuid)

mutable struct GnuPlotScript
    _registered_data::Dict{RegisteredData_UUID,Any}
    _script::String
    _any_plot::Bool
    _direct_plot_io::Union{Nothing,IO}

    function GnuPlotScript(;direct_plot = true)
        # manage direct plot
        #
        io = nothing
        if direct_plot
            io = open(Cmd([gnuplot_exe]),write=true)
            if !iswritable(io)
                @warn "Cannot start gnuplot executable $gnuplot_exe"
                close(io)
                io = nothing
            end
        end
        
        # other default values
        #
        registered_data=Dict{RegisteredData_UUID,Any}()
        script = String("")
        any_plot = false
        
        gp = new(registered_data,script,any_plot,io)
    end
end

# check if data has already been registered
#
function is_registered(gp::GnuPlotScript,uuid::RegisteredData_UUID)
    haskey(gp._registered_data,uuid)
end

# write data
# ID << EOD
# data
# END
function _write_data(io::IO, uuid::RegisteredData_UUID, data::AbstractVecOrMat)
    println(io,"$(to_gnuplot_uuid(uuid)) << EOD")
    writedlm(io,data)
    println(io,"EOD")
end

function _write_data(io::IO,gp::GnuPlotScript)
    for (k,d) in gp._registered_data
        _write_data(io,k,d)
    end 
end

function _write_script(io::IO,gp::GnuPlotScript)
    _write_data(io,gp)
    print(io,gp._script)
end

# ================================================================

# private methods to write data:
# -> use them systematically. Reason contains the extra logic used for direct plotting
#
function _append_data(gp::GnuPlotScript,data::AbstractVecOrMat)::RegisteredData_UUID
    # already registered
    uuid = hash(data)

    # no, register it
    if !is_registered(gp,uuid)
        gp._registered_data[uuid]=data
    end

    if gp._direct_plot_io != nothing
        try
            _write_data(gp._direct_plot_io,uuid,data)
        catch
            @warn "Broken pipe"
            close(gp._direct_plot_io)
            gp._direct_plot_io=nothing
        end
    end
    
    uuid
end

function _append_to_script(gp::GnuPlotScript,line::AbstractString)
    # Append to script
    #
    line *= "\n"
    gp._script *= line

    # If direct plot is active
    # also pipe the line
    #
    if gp._direct_plot_io != nothing
        try
            write(gp._direct_plot_io,line)
        catch
            @warn "Broken pipe"
            close(gp._direct_plot_io)
            gp._direct_plot_io=nothing
        end
    end
    
    gp
end

# Register data and return associated data uuid.
#
function register_data(gp::GnuPlotScript,data::AbstractVecOrMat;
                       copy_data::Bool=true)::RegisteredData_UUID
    if copy_data
        data = deepcopy(data)
    end

    _append_data(gp,data)
end


# Detect first plot when using free_form
#
function _contains_plot_p(gp_line::AbstractString)
    space = "^([ \t]*)"
    r = "$(space)splot |$(space)plot "
    r = Regex(r)

    match(r,gp_line) !== nothing
end


function free_form(gp::GnuPlotScript,gp_line::AbstractString)
    # Detect plot instruction
    if _contains_plot_p(gp_line)
        gp._any_plot = true 
    end
    # 
    _append_to_script(gp,gp_line)
end

function set_title(gp::GnuPlotScript,title::AbstractString;
                   enhanced::Bool = false)
    command = "set title '$title'"
    if enhanced==false
        command *= " noenhanced"
    end

    _append_to_script(gp,command)
end

function _plot(gp::GnuPlotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString;
               # true: plot triggered by gnuplot "plot"
               reset_plot::Bool)
    @assert is_registered(gp,uuid)

    # Detect replot
    #
    replot = false
    if reset_plot
        gp._any_plot = false
    else
        if gp._any_plot
            replot = true
        end
    end

    # create command
    #
    command = ""
    if replot
        command *= "re"
    end
    #
    command *= "plot $(to_gnuplot_uuid(uuid)) " * plot_arg

    _append_to_script(gp,command)

    gp._any_plot = true
end

function plot(gp::GnuPlotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString)
    _plot(gp,uuid,plot_arg,reset_plot=true)
end

# Like gnuplot "replot", with the difference that we automatically
# switch to "plot" when there is no initial plot.
#
# Note that we can force "replot" thanks to "force_replot"
#
function replot(gp::GnuPlotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString;
                force_replot::Bool=false)

    if force_replot
        gp._any_plot = true
    end
    
    _plot(gp,uuid,plot_arg,reset_plot=false)
end

# vertical ----------------
#
function add_vertical_line(gp::GnuPlotScript,position::Float64;name::Union{AbstractString,Nothing})
    command = ""
    if name != Nothing
        command  *= "set label at $position, 0.0 '$name' rotate by 90 front left offset -1,1,0 tc ls 1\n"
    end
    command *= "set arrow from $position, graph 0 to $position, graph 1 nohead front\n"

    _append_to_script(gp,command)
end

# ================

function write_script(script_file::AbstractString,gp::GnuPlotScript)
    io = open(script_file, "w");

    _write_script(io,gp)
    
    close(io)
end
