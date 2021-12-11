export GnuPlotScript
export register_data
export free_form
export plot, replot
export set_title
export write_script

using DelimitedFiles

# By now we directly use hash() as data_id. However, this will maybe change in
# the future, that's why we declare dedicated type.
#
const RegisteredData_UUID = typeof(hash(1))

# Gnuplot exe
# TODO: windows!
#
const gnuplot_exe = "gnuplot"

# convert data id to gnuplot id
#
to_gnuplot_uuid(uuid::RegisteredData_UUID) = "\$G"*string(uuid)

# TODO: add this at construction tiem and modify append
# io = open((@cmd "gnuplot"),write=true)
# write_script(io,gp)
# isreadable(io)
# close(io)

mutable struct GnuPlotScript
    _registered_data::Dict{RegisteredData_UUID,Any}
    _script::String
    _any_plot::Bool
    _direct_plot_io::Union{Nothing,IO}
end 

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
    
    GnuPlotScript(registered_data,script,any_plot,io)
end

# check if data has already been registered
#
function is_registered(gp::GnuPlotScript,uuid::RegisteredData_UUID)
    haskey(gp._registered_data,uuid)
end

# private methods to write data:
# -> use them systematically. Reason contains the extra logic used for direct plotting
#
function _append_data(gp::GnuPlotScript,data::AbstractVecOrMat)::RegisteredData_UUID
    # already registered
    uuid = hash(data)
    
    if !is_registered(gp,uuid)
        gp._registered_data[uuid]=data
    end

    uuid
end
function _append_to_script(gp::GnuPlotScript,line::AbstractString)
    gp._script *= line 

    if gp._direct_plot_io != nothing
        if iswritable(gp._direct_plot_io)
            write(gp._direct_plot_io,line)
        else
            @warn "Broken pipe"
            close(gp._direct_plot_io)
            gp._direct_plot_io=nothing
        end
    end 
    gp
end

function _append_to_script_newline(gp::GnuPlotScript,line::AbstractString)
    _append_to_script(gp, line * "\n")
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


# function register_data(gp::GnuplotScript,data::Spectrum;
#                         copy_data::Bool=true)::RegisteredData_UUID
#     register_data(gp,hcat(data.X,data.Y),copy_data=copy_data)
# end

function free_form(gp::GnuPlotScript,gp_line::AbstractString)
    _append_to_script_newline(gp,gp_line)
end

function set_title(gp::GnuPlotScript,title::AbstractString;
                   enhanced::Bool = false)
    command = "set title '$title'"
    if enhanced==false
        command *= " noenhanced"
    end

    _append_to_script_newline(gp,command)
end

function _plot(gp::GnuPlotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString; reset_plot::Bool)
    @assert is_registered(gp,uuid)

    # if the plot is not reset, we must check if there is any previous
    # plot to chose between plot or replot
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

    _append_to_script_newline(gp,command)
end

function plot(gp::GnuPlotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString)
    _plot(gp,uuid,plot_arg,reset_plot=true)
end

function replot(gp::GnuPlotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString)
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

    _append_to_script_newline(gp,command)
end

# ================

function write_data(io::IO,gp::GnuPlotScript)
    for (k,d) in gp._registered_data
        println(io,"$(to_gnuplot_uuid(k)) << EOD")
        writedlm(io,d)
        println(io,"EOD")
    end 
end

function write_script(io::IO,gp::GnuPlotScript)
    write_data(io,gp)
    print(io,gp._script)
end

function write_script(script_file::AbstractString,gp::GnuPlotScript)
    io = open(script_file, "w");

    write_script(io,gp)
    
    # add a final replot to be sure that everything is plotted
    # println(io,"replot")
 
    close(io)
end
    
# ****************************************************************
# DEMO 
# ****************************************************************
# gp = GnuPlotScript()

# id_1 = register_data(gp,10*rand(5))
# id_2 = register_data(gp,10*rand(5,2))

# gp = plot(gp,id_1,"u 1 w l")
# gp = replot(gp,id_2,"u 1:2 w l")
# gp = add_vertical_line(gp,5.0,name="toto")
# gp = add_vertical_line(gp,2.0,name="titititito")

# write("demo.gp",gp)
