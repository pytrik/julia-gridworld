push!(LOAD_PATH, pwd());
using Revise
using ASCIICanvas

background = load_sprite("achtergrond", "map.sprite")
const wallCoordinates = [[(2, j) for j in 0:4]; [(5, j) for j in 3:7]; [(j, 7) for j in 5:10]]

const worldHeight = count(['·' == c for c in background.chars[:,1]])
const worldWidth = count(['·' == c for c in background.chars[1,:]])
const nState = worldWidth * worldHeight

struct Action
    name::Symbol
    index::Int64
    move::Tuple{Int64, Int64}
end

const actions = [
    Action(:up, 1, (0, 1)),
    Action(:down, 2, (0, -1)),
    Action(:left, 3, (-1, 0)),
    Action(:right, 4, (1, 0))
]

wallSprites = [Sprite("wall","#"; foreground = :black, background = :red, x=xy[1]*2, y =xy[2]) for xy in wallCoordinates]
world = ASCanvas(size(background)[2], size(background)[1], [background; wallSprites])

coordinates2state(x::Int64,y::Int64) = 1 + (x + worldWidth*y)
state2coordinates(state::Int64) = ( (state-1) % worldWidth , (state-1) ÷ worldWidth)

function show_state_as_world(world::ASCanvas, state::Int64)
    coords = state2coordinates(state)
    hero = Sprite("wall","@"; foreground = :blue, background = :none, x = coords[1] * 2, y = coords[2])
    push!(world.stack, hero)
    print(world)
    pop!(world.stack)
end

function can_move(state::Int64, action::Action)
    coords = state2coordinates(state)
    coords = Tuple([coords...] + [action.move...])

    if coords[1] < 0 ||
       coords[1] >= worldWidth
        return false
     end

    if coords[2] < 0 ||
       coords[2] >= worldHeight
       return false
    end

    if coords ∈ wallCoordinates
        return false
    end

    return true
end

list_feasible_actions(state::Int64) = actions[map(act -> can_move(state, act), actions)]

s = 96
show_state_as_world(world, s);
list_feasible_actions(s)

# list_feasible_actions

# apply_state

# lol, dit is een commpent