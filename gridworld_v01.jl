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
    tempWorld = ASCanvas(world.width, world.height, [world.stack; hero])
    print(tempWorld)
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
enact(state::Int64, action::Action) = coordinates2state( Tuple([state2coordinates(state)...] + [action.move...])... )
enact(state::Int64, actionIndex::Int64) = enact(state, actions[actionIndex])

const stateActionMatrix = [enact(j,k) for j in 1:nState, k in 1:4]
const startState = 1
const endState = coordinates2state(6,6)

reward(targetState::Int64) = targetState == endState ? 1 : 0

# ΔQ[ S[t], A[t] ] = α ( R[t+1] + γ max_a{ Q[ S[t+1], a ]} - Q[ S[t], A[t] ] )
function updateQ!(Q::Array{Float64,2}, α::Float64, γ::Float64, currentState::Int64, actionIndex::Int64)
    nextState = enact(currentState, actionIndex)
    nextReward = reward(nextState)
    expectedFutureReward = γ * max(Q[nextState,:]...)
    Q[currentState, actionIndex] = Q[currentState, actionIndex] + α * ( nextReward + expectedFutureReward - Q[currentState, actionIndex])
    return nextState
end 

learningPolicy(state::Int64) = rand(list_feasible_actions(state)).index

Q = zeros(Float64, nState, length(actions))
state = startState;

epochs = 0

for k=1:1000000
    state = updateQ!(Q, 0.1, 0.9, state, learningPolicy(state))
    if state == endState
        state = startState
        epochs +=1 
    end
end

function bestPolicy(state::Int64)
    feasActIndex = map(x->x.index, list_feasible_actions(state))
    value, ind = findmax(Q[state,feasActIndex])
    return feasActIndex[ind]
end

state = startState
show_state_as_world(world, state)

state = enact(state, bestPolicy(state))
show_state_as_world(world, state)