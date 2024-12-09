using IntervalArithmetic
using IntervalArithmetic.Symbols
using UUIDs
using Random
using Distributions

include("../../../utils/ahp/crisp_pcm/v1/crisp_pcm.jl")
using .CrispPCM

include("../../../utils/ahp/interval_pcm/v1/interval_pcm.jl")
using .IntervalPCM

include("../../../utils/ahp/twofold_interval/v1/twofold_interval.jl")
using .TwofoldIntervalArithmetic

include("../../../utils/ahp/twofold_interval_pcm/v1/twofold_interval_pcm.jl")
using .TwofoldIntervalPCM

SimulationCase = @NamedTuple{
    id::String,
    A₁::Matrix{Interval{T}},
    A₂::Matrix{Interval{T}},
    𝓐::Matrix{TwofoldInterval{T}}
} where {T<:Real}

function generateSimulationCases(
    n::Integer,
    crispPCMCount::Integer,
    intervalPCMCountPerCrispPCM::Integer,
    S::Real=9.0,
    randomizeWidth::Real=log(5) / 2
)::Vector{SimulationCase}
    simulation_cases = SimulationCase[]

    for _ in 1:crispPCMCount
        crisp_pcm = generateConsistentCrispPCM(n, S, 500000)
        for _ in 1:intervalPCMCountPerCrispPCM
            A₁ = discretizate(randamizedIntervalPCM(crisp_pcm, randomizeWidth), S)
            A₂ = discretizate(randamizedIntervalPCM(crisp_pcm, randomizeWidth), S)
            𝒜⁻ = intersect_interval.(A₁, A₂)
            𝒜⁺ = hull.(A₁, A₂)
            𝓐 = twofoldIntervalMatrix(𝒜⁻, 𝒜⁺)
            id = string(uuid4())
            push!(simulation_cases, (id=id, A₁=A₁, A₂=A₂, 𝓐=𝓐))
        end
    end

    return simulation_cases
end

function generateCrispPCM(n::Integer, S::T)::Matrix where {T<:Real}
    if S <= 1
        throw(ArgumentError("S must be larger than 1."))
    end

    A = ones(n, n)

    for i in 1:n
        for j in (i+1):n
            aᵢⱼ = exp(rand(Uniform(-log(S), log(S))))
            A[i, j] = aᵢⱼ
            A[j, i] = 1 / aᵢⱼ
        end
    end

    if !isCrispPCM(A)
        throw(ArgumentError("Generated matrix is not a valid crisp PCM."))
    end

    return A
end

function generateConsistentCrispPCM(
    n::Integer,
    S::T,
    max_retries::Integer=50
)::Matrix where {T<:Real}
    for attempt in 1:max_retries
        A = generateCrispPCM(n, S)
        isConsistent = CR(A) < 0.1
        if isConsistent
            return A
        end
    end
    throw(ArgumentError("Maximum retry count reached."))
end

@inline function randamizedIntervalPCM(
    A::Matrix{T},
    width::Real=0.05 # 自然対数スケールでの幅
)::Matrix{Interval{T}} where {T<:Real}
    if size(A, 1) != size(A, 2)
        throw(ArgumentError("A must be square matrix."))
    end
    n = size(A, 2)

    B = log.(A)
    C = fill(1 .. 1, (n, n))

    for i = 1:n
        for j = i:n
            if i == j
                continue
            end
            r₁ = rand(Uniform(1e-8, width))
            r₂ = rand(Uniform(1e-8, width))
            C[i, j] = exp(B[i, j] - r₁) .. exp(B[i, j] + r₂)
        end
    end

    for i = 1:n
        for j = 1:i
            if i == j
                continue
            end
            C[i, j] = 1 / C[j, i]
        end
    end

    if !isIntervalPCM(C)
        throw(ArgumentError("Generated matrix is not a valid interval PCM."))
    end

    return C
end

@inline function discretizate(a::T, S::Real)::T where {T<:Real}
    # sorted_scale = [1/9, 1/8, ..., 1/2, 1, 2, ..., 8, 9] if S = 9
    sorted_scale = sort(comparisonScale(S))
    # boundaries = [1/sqrt(9*8), 1/sqrt(8*7), ..., 1/sqrt(3*2), 1/sqrt(2*1), sqrt(1*2), sqrt(2*3), ..., sqrt(7*8), sqrt(8*9)] if S = 9
    boundaries = [sqrt(sorted_scale[i] * sorted_scale[i+1]) for i in 1:length(sorted_scale)-1]

    for i in eachindex(boundaries)
        if a ≤ boundaries[i]
            return sorted_scale[i]
        end
    end

    return last(sorted_scale)
end

@inline function discretizate(A::Matrix{T}, S::Real)::Matrix{T} where {T<:Real}
    return map(a -> discretizate(a, S), A)
end

@inline function discretizate(A::Matrix{Interval{T}}, S::Real)::Matrix{Interval{T}} where {T<:Real}
    return map(a -> discretizate(inf(a), S) .. discretizate(sup(a), S), A)
end

@inline function comparisonScale(S::Real)
    if S < 1
        throw(ArgumentError("S must be positive int."))
    end
    return vcat(1 ./ (S:-1:2), [1], 2:S)
end
