module ASCIICanvas

using DelimitedFiles
using Crayons

export ASColor, Sprite, ASCanvas, move!, move_to!, move_down!, move_left!, move_right!, move_up!, load_sprite

# this file contains all cool monospace characters.
# I "verified" that these are displayed as "proper" monospace
# in VSCode / Julia
# data = readdlm("verified_monospace_characters.txt",' ')
# MonospaceCharacters = Char.(Int64.(data[:,1]))

# print(Crayon(foreground = :default, background = :green), "aap")

abstract type AbstractSprite end

mutable struct ASColor
    foreground::Union{Nothing, Symbol, Tuple{Int64,Int64,Int64}} # either :none, :default, :color_name or nice RGB tuple
    background::Union{Nothing, Symbol, Tuple{Int64,Int64,Int64}} # either :none, :default, :color_name or nice RGB tuple
    opaqueSpace::Bool
end

mutable struct Sprite <: AbstractSprite
    name::String
    chars::Array{Char,2}
    x::Int64
    y::Int64
    color::ASColor
end

function Sprite(name::String, str::AbstractString; x::Int64=0, y::Int64=0, foreground::Union{Nothing, Symbol, Tuple{Int64,Int64,Int64}}=:default, background::Union{Nothing, Symbol, Tuple{Int64,Int64,Int64}}=:none, opaqueSpace::Bool=true)
    chars = permutedims(hcat([[c for c in s] for s in split(str,'\n')]...),[2,1])
    color = ASColor(foreground, background, opaqueSpace)
    return Sprite(name, chars, x, y, color)
end

function load_sprite(name, filename::String; x::Int64=0, y::Int64=0, foreground::Union{Nothing, Symbol, Tuple{Int64,Int64,Int64}}=:default, background::Union{Nothing, Symbol, Tuple{Int64,Int64,Int64}}=:none, opaqueSpace::Bool=true)
    fid = open(filename,"r")
    data = read(fid,String)
    close(fid)
    data = replace(data,"\r\n"=>"\n")
    return Sprite(name, data; x=x, y=y, foreground=foreground, background=background, opaqueSpace=opaqueSpace)
end

Base.size(s::Sprite) = size(s.chars)

function move_to!(ss::Sprite,x::Int64,y::Int64)
    ss.x = x;
    ss.y = y;
end

function move!(ss::Sprite,x::Int64,y::Int64)
    ss.x += x;
    ss.y += y;
end

move_up!(ss::Sprite,n::Int64=1) = ss.y += n;
move_down!(ss::Sprite,n::Int64=1) = ss.y -= n;
move_left!(ss::Sprite,n::Int64=1) = ss.x -= n;
move_right!(ss::Sprite,n::Int64=1) = ss.x += n;

function move!(ss::Sprite,d::Symbol,n::Int64=1)
    if d==:up || d==:u
        return move_up!(ss,n)
    elseif d==:down || d==:d
        return move_down!(ss,n)
    elseif d==:left || d==:l
        return move_left!(ss,n)
    elseif d==:right || d==:r
        return move_right!(ss,n)
    elseif d==:upleft || d==:ul
        return move!(ss,n,-n)
    elseif d==:upright || d==:ur
        return move!(ss,n, n)
    elseif d==:downleft || d==:dl
        return move!(ss,-n,-n)
    elseif d==:downright || d==:dr
        return move!(ss,-n, n)
    else
        error("Direction not recognized")
    end
end


mutable struct ASCanvas 
    #size::Tuple{Int64,Int64} # width and height.
    width::Int64
    height::Int64
    stack::Array{AbstractSprite,1}
end

ASCanvas(s::Tuple{Int64,Int64}, stack::Array{Sprite,1}) = ASCanvas(s[2],s[1],stack)

function Base.print(ss::Sprite)
    print("Sprite: (\"" * ss.name * "\")" * "\t@" * string((ss.x,ss.y)))
    print("\t[" * string(ss.color.foreground) * "/" * string(ss.color.background) * "]" )
    println("\topaqueSpace = " * string(ss.color.opaqueSpace))
    printBG = ss.color.background == :none ? :default : ss.color.background
    for row in eachrow(ss.chars)
        for c in row
            if c == ' ' && !ss.color.opaqueSpace
                print(Crayon(foreground = ss.color.foreground, background = :default), c)
            else
                print(Crayon(foreground = ss.color.foreground, background = printBG), c)
            end
        end
        print('\n')
    end
end


function combine_chars(char::Char,col::ASColor,charNew::Char,colNew::ASColor)
    outChar = charNew
    # outCol = copy(colNew)
    outCol = ASColor(colNew.foreground,colNew.background,true)

    if charNew == ' ' && !colNew.opaqueSpace 
        outChar = char
        outCol.foreground = col.foreground
        outCol.background = col.background
    else
        if colNew.foreground == :none
            outCol.foreground = col.foreground
        end
        
        if colNew.background == :none
            outCol.background = col.background
        end
    end

    return (outChar, outCol)
end

function evaluate_stack(asc::ASCanvas)

    outChars = [' ' for j in 1:asc.height, k in 1:asc.width]
    outColor = [ASColor(:default,:default,true) for j in 1:asc.height, k in 1:asc.width]

    for s in asc.stack
        xRange = [i for i in 1:size(s.chars,2) if 1 <= i+s.x <= asc.width]
        yRange = [i for i in 1:size(s.chars,1) if 1 <= 1 + size(s.chars,1)-i + s.y <= asc.height]
        croppedChars = s.chars[yRange,xRange]
        tx = max(s.x,0)
        ty = max(s.y,0)

        xx = 1+tx : tx+length(xRange)
        yy = (asc.height + 1 - ty - length(yRange)) : (asc.height - ty)

        if tx < asc.width && ty < asc.height
            combined = combine_chars.(outChars[yy, xx], outColor[yy, xx], croppedChars, [s.color for i in yRange, j in xRange])
            outChars[yy, xx] .= [c[1] for c in combined]
            outColor[yy, xx] .= [c[2] for c in combined]
        end
    end

    return (outChars, outColor)
end

function Base.print(asc::ASCanvas)
    combined = evaluate_stack(asc)

    for j=1:size(combined[1],1)
        for k=1:size(combined[1],2)
            print(Crayon(foreground = combined[2][j,k].foreground, background = combined[2][j,k].background), combined[1][j,k])
        end
        print(Crayon(foreground = :default, background = :default),'\n')
    end
end

end
