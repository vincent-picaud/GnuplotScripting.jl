export GnuplotScript
export register_data
export free_form
export plot, replot
export set_title
export add_vertical_line
export write_script

using DelimitedFiles

# Data identifier
#
struct RegisteredData_UUID
    _hash::UInt64
    RegisteredData_UUID(any) = new(hash(any))
end

# Show a well formed gnuplot id
import Base: show
Base.show(io::IO,uuid::RegisteredData_UUID) = print(io,"\$G"*string(uuid._hash))


# Gnuplot exe
# TODO: windows!
#
@static if Sys.iswindows()
    const gnuplot_exe = "gnuplot.exe"
else
    const gnuplot_exe = "gnuplot"
end

@doc raw"""
```julia
gp = GnuplotScript(;direct_plot = true)
```

Create a gnuplot script `gp`. If `direct_plot` is true, simultaneously
plot the registered operations.

# Usage example

You can perform a simple plot as follows:

```julia
gp = GnuplotScript(;direct_plot = true)

X=[-pi:0.1:pi;];
Ys = sin.(X);
Yc = cos.(X);

id = register_data(gp,hcat(X,Ys,Yc))
free_form(gp,"replot '$id' u 1:3 w l t 'cos'")
free_form(gp,"replot '$id' u 1:2 w l t 'sin'")
```

The plot will be created immediately.

# Also see
- [`register_data`](@ref) 
- [`free_form`](@ref) 
"""
mutable struct GnuplotScript
    _registered_data::Dict{RegisteredData_UUID,Any}
    _script::String
    _any_plot::Bool
    _direct_plot_io::Union{Nothing,IO}

    function GnuplotScript(;direct_plot = true)
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
function is_registered(gp::GnuplotScript,uuid::RegisteredData_UUID)
    haskey(gp._registered_data,uuid)
end

# write data
# ID << EOD
# data
# END
function _write_data(io::IO, uuid::RegisteredData_UUID, data::AbstractVecOrMat)
    println(io,"$uuid << EOD")
    writedlm(io,data)
    println(io,"EOD")
end

function _write_data(io::IO,gp::GnuplotScript)
    for (k,d) in gp._registered_data
        _write_data(io,k,d)
    end 
end

function _write_script(io::IO,gp::GnuplotScript)
    _write_data(io,gp)
    print(io,gp._script)
end

# ================================================================

# private methods to write data:
# -> use them systematically. Reason contains the extra logic used for direct plotting
#
function _append_data(gp::GnuplotScript,data::AbstractVecOrMat)::RegisteredData_UUID
    # already registered
    uuid = RegisteredData_UUID(data)

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

function _append_to_script(gp::GnuplotScript,line::AbstractString)
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

@doc raw"""
```julia
register_data(gp::GnuplotScript,
              data::AbstractVecOrMat;
              copy_data::Bool=true) -> id
```

Register data and return the associated data identifier. Registered
data is embedded in the plot script file. The returned `id` is used to
reference registered data.

# Usage example

```julia
gp = GnuplotScript()

M = rand(10,3)

id = register_data(gp, M)

free_form(gp,"replot $id u 1:2")
free_form(gp,"replot $id u 1:3")
```

"""
function register_data(gp::GnuplotScript,data::AbstractVecOrMat;
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

@doc raw"""
```julia
free_form(gp::GnuplotScript,gp_line::AbstractString)
```

Write gnuplot commands. This command line is directly forwarded to
Gnuplot. The only difference is that you can use `replot` even for the
first plot. This is convenient when you chain plots, you do not have
to worry if the current command is the first plot.

# Usage example 

```julia
using GnuplotScripting

gp = GnuplotScript()

free_form(gp, "replot sin(x) lw 2 t 'a trigonometric function'")
```

"""
function free_form(gp::GnuplotScript,gp_line::AbstractString)
    # Detect replot instruction.
    # If no previous plot, do "replot" => "plot"
    #
    r = r"^([ \t]*)(replot) "
    if match(r,gp_line) !== nothing
        if gp._any_plot == false
            gp_line = replace(gp_line,r"^([ \t]*)(replot) "=>s"\g<1>plot ")
        end
    end
    
    # Detect plot instruction
    # If one is detected, set any_plot = true
    #
    if _contains_plot_p(gp_line)
        gp._any_plot = true 
    end
    # 
    _append_to_script(gp,gp_line)
end

@doc raw"""
```julia
set_title(gp::GnuplotScript,title::AbstractString;
                   enhanced::Bool = false)
```

Define plot title. If `enhanced` is true, some characters are
processed in a special way. By example `_` subscripts text.
"""
function set_title(gp::GnuplotScript,title::AbstractString;
                   enhanced::Bool = false)
    command = "set title '$title'"
    if enhanced==false
        command *= " noenhanced"
    end

    _append_to_script(gp,command)
end

function _plot(gp::GnuplotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString;
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
    command *= "plot $uuid " * plot_arg

    _append_to_script(gp,command)

    gp._any_plot = true
end


# ****************************************************************
# Dedicated function / recipes
# ****************************************************************
#

function plot(gp::GnuplotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString)
    _plot(gp,uuid,plot_arg,reset_plot=true)
end

# Like gnuplot "replot", with the difference that we automatically
# switch to "plot" when there is no initial plot.
#
# Note that we can force "replot" thanks to "force_replot"
#
function replot(gp::GnuplotScript,uuid::RegisteredData_UUID,plot_arg::AbstractString;
                force_replot::Bool=false)

    if force_replot
        gp._any_plot = true
    end
    
    _plot(gp,uuid,plot_arg,reset_plot=false)
end

# vertical line ================
#

"""
    add_vertical_line(gp::GnuplotScript,position::Float64;name::Union{AbstractString,Nothing})

Add a vertical bar with a label
"""
function add_vertical_line(gp::GnuplotScript,position::Float64;name::Union{AbstractString,Nothing})
    command = ""
    if name != Nothing
        command  *= "set label at $position, 0.0 '$name' rotate by 90 front left offset -1,1,0 tc ls 1\n"
    end
    command *= "set arrow from $position, graph 0 to $position, graph 1 nohead front\n"

    _append_to_script(gp,command)
end

# ****************************************************************
# Write script
# ****************************************************************
#

"""
    write_script(script_file::AbstractString,gp::GnuplotScript)

Write script with embedded data for future use.

# Usage

```julia
gp = GnuplotScript()

...

write_script("gnuplot_script.gp",gp)
```

You can replay the script using Gnuplot:
```sh
    gnuplot gnuplot_script.gp
```

If you want to keep the gnuplot session opened, add a final `-`

```sh
    gnuplot gnuplot_script.gp -
```
"""
function write_script(script_file::AbstractString,gp::GnuplotScript)
    io = open(script_file, "w");

    _write_script(io,gp)
    
    close(io)
end
