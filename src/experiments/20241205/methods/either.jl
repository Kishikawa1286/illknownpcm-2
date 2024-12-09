using IntervalArithmetic
using IntervalArithmetic.Symbols
using HiGHS
using JuMP

include("../../../utils/ahp/nearly_equal/v1/nearly_equal.jl")
using .NearlyEqual

include("../../../utils/ahp/interval_pcm/v1/interval_pcm.jl")
using .IntervalPCM

include("../../../utils/ahp/twofold_interval/v1/twofold_interval.jl")
using .TwofoldIntervalArithmetic

include("../../../utils/ahp/twofold_interval_pcm/v1/twofold_interval_pcm.jl")
using .TwofoldIntervalPCM

LPResult = @NamedTuple{
    wᴸ⁺::Vector{T}, wᴸ⁻::Vector{T},
    wᵁ⁻::Vector{T}, wᵁ⁺::Vector{T},
    optimalValue::T
} where {T<:Real}

function TFIWs_either(
    A::Matrix{Interval{T}}
) where {T<:Real}
    if !isIntervalPCM(A)
        throw(ArgumentError("Given matrix is not valid as an interval matrix."))
    end

    ε = 1e-12
    n = size(A, 1)

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    try
        @variable(model, wᴸ⁻[i=1:n] ≥ ε)
        @variable(model, wᵁ⁻[i=1:n] ≥ ε)
        @variable(model, wᴸ⁺[i=1:n] ≥ ε)
        @variable(model, wᵁ⁺[i=1:n] ≥ ε)
        @variable(model, wᴸ⁻ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᴸ⁻ᵁ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᴸ⁺ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᴸ⁺ᵁ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁻ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁻ᵁ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁺ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁺ᵁ[i=1:n, j=1:n] ≥ ε)

        for i = 1:n
            wᵢᴸ⁻ = wᴸ⁻[i]
            wᵢᵁ⁻ = wᵁ⁻[i]
            wᵢᴸ⁺ = wᴸ⁺[i]
            wᵢᵁ⁺ = wᵁ⁺[i]
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᴸ⁻ ≤ wᵢᵁ⁻)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᵁ⁺)

            wᵢᴸⁱ⁻ᵁ = wᴸ⁻ᵁ[i, i]
            wᵢᴸⁱ⁺ᵁ = wᴸ⁺ᵁ[i, i]
            wᵢᵁⁱ⁻ᴸ = wᵁ⁻ᴸ[i, i]
            wᵢᵁⁱ⁺ᴸ = wᵁ⁺ᴸ[i, i]
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᵁⁱ⁻ᴸ)
            @constraint(model, wᵢᵁⁱ⁻ᴸ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᵁⁱ⁺ᴸ)
            @constraint(model, wᵢᵁⁱ⁺ᴸ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᴸⁱ⁻ᵁ)
            @constraint(model, wᵢᴸⁱ⁻ᵁ ≤ wᵢᵁ⁺)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᴸⁱ⁺ᵁ)
            @constraint(model, wᵢᴸⁱ⁺ᵁ ≤ wᵢᵁ⁺)

            ∑ⱼwⱼᴸⁱ⁻ᴸ = sum(map(j -> wᴸ⁻ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᴸⁱ⁻ᵁ = sum(map(j -> wᴸ⁻ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᴸ⁻ + ∑ⱼwⱼᴸⁱ⁻ᵁ ≥ 1)
            @constraint(model, wᵢᴸⁱ⁻ᵁ + ∑ⱼwⱼᴸⁱ⁻ᴸ ≤ 1)

            ∑ⱼwⱼᴸⁱ⁺ᴸ = sum(map(j -> wᴸ⁺ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᴸⁱ⁺ᵁ = sum(map(j -> wᴸ⁺ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᴸ⁺ + ∑ⱼwⱼᴸⁱ⁺ᵁ ≥ 1)
            @constraint(model, wᵢᴸⁱ⁺ᵁ + ∑ⱼwⱼᴸⁱ⁺ᴸ ≤ 1)

            ∑ⱼwⱼᵁⁱ⁻ᴸ = sum(map(j -> wᵁ⁻ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᵁⁱ⁻ᵁ = sum(map(j -> wᵁ⁻ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᵁⁱ⁻ᴸ + ∑ⱼwⱼᵁⁱ⁻ᵁ ≥ 1)
            @constraint(model, wᵢᵁ⁻ + ∑ⱼwⱼᵁⁱ⁻ᴸ ≤ 1)

            ∑ⱼwⱼᵁⁱ⁺ᴸ = sum(map(j -> wᵁ⁺ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᵁⁱ⁺ᵁ = sum(map(j -> wᵁ⁺ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᵁⁱ⁺ᴸ + ∑ⱼwⱼᵁⁱ⁺ᵁ ≥ 1)
            @constraint(model, wᵢᵁ⁺ + ∑ⱼwⱼᵁⁱ⁺ᴸ ≤ 1)

            for j = 1:n
                if i == j
                    continue
                end

                wⱼᴸ⁻ = wᴸ⁻[j]
                wⱼᵁ⁻ = wᵁ⁻[j]
                wⱼᴸ⁺ = wᴸ⁺[j]
                wⱼᵁ⁺ = wᵁ⁺[j]

                wⱼᴸⁱ⁻ᴸ = wᴸ⁻ᴸ[i, j]
                wⱼᴸⁱ⁻ᵁ = wᴸ⁻ᵁ[i, j]
                wⱼᴸⁱ⁺ᴸ = wᴸ⁺ᴸ[i, j]
                wⱼᴸⁱ⁺ᵁ = wᴸ⁺ᵁ[i, j]
                wⱼᵁⁱ⁻ᴸ = wᵁ⁻ᴸ[i, j]
                wⱼᵁⁱ⁻ᵁ = wᵁ⁻ᵁ[i, j]
                wⱼᵁⁱ⁺ᴸ = wᵁ⁺ᴸ[i, j]
                wⱼᵁⁱ⁺ᵁ = wᵁ⁺ᵁ[i, j]

                @constraint(model, wⱼᴸ⁺ ≤ wⱼᴸⁱ⁻ᴸ)
                @constraint(model, wⱼᴸⁱ⁻ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᴸ⁺ ≤ wⱼᴸⁱ⁺ᴸ)
                @constraint(model, wⱼᴸⁱ⁺ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᴸ⁺ ≤ wⱼᵁⁱ⁻ᴸ)
                @constraint(model, wⱼᵁⁱ⁻ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᴸ⁺ ≤ wⱼᵁⁱ⁺ᴸ)
                @constraint(model, wⱼᵁⁱ⁺ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᴸⁱ⁻ᵁ)
                @constraint(model, wⱼᴸⁱ⁻ᵁ ≤ wⱼᵁ⁺)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᴸⁱ⁺ᵁ)
                @constraint(model, wⱼᴸⁱ⁺ᵁ ≤ wⱼᵁ⁺)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᵁⁱ⁻ᵁ)
                @constraint(model, wⱼᵁⁱ⁻ᵁ ≤ wⱼᵁ⁺)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᵁⁱ⁺ᵁ)
                @constraint(model, wⱼᵁⁱ⁺ᵁ ≤ wⱼᵁ⁺)

                ∑ₖwₖᴸⁱ⁻ᴸ = sum(map(k -> wᴸ⁻ᴸ[i, k], filter(k -> k != i && k != j, 1:n)))
                ∑ₖwₖᴸⁱ⁻ᵁ = sum(map(k -> wᴸ⁻ᵁ[i, k], filter(k -> k != i, 1:n)))
                @constraint(model, wⱼᴸⁱ⁻ᴸ + ∑ₖwₖᴸⁱ⁻ᵁ ≥ 1)
                @constraint(model, wⱼᴸⁱ⁻ᵁ + wᵢᴸ⁻ + ∑ₖwₖᴸⁱ⁻ᴸ ≤ 1)

                ∑ₖwₖᴸⁱ⁺ᴸ = sum(map(k -> wᴸ⁺ᴸ[i, k], filter(k -> k != i && k != j, 1:n)))
                ∑ₖwₖᴸⁱ⁺ᵁ = sum(map(k -> wᴸ⁺ᵁ[i, k], filter(k -> k != i, 1:n)))
                @constraint(model, wⱼᴸⁱ⁺ᴸ + ∑ₖwₖᴸⁱ⁺ᵁ ≥ 1)
                @constraint(model, wⱼᴸⁱ⁺ᵁ + wᵢᴸ⁺ + ∑ₖwₖᴸⁱ⁺ᴸ ≤ 1)

                ∑ₖwₖᵁⁱ⁻ᴸ = sum(map(k -> wᵁ⁻ᴸ[i, k], filter(k -> k != i, 1:n)))
                ∑ₖwₖᵁⁱ⁻ᵁ = sum(map(k -> wᵁ⁻ᵁ[i, k], filter(k -> k != i && k != j, 1:n)))
                @constraint(model, wⱼᵁⁱ⁻ᴸ + wᵢᵁ⁻ + ∑ₖwₖᵁⁱ⁻ᵁ ≥ 1)
                @constraint(model, wⱼᵁⁱ⁻ᵁ + ∑ₖwₖᵁⁱ⁻ᴸ ≤ 1)

                ∑ₖwₖᵁⁱ⁺ᴸ = sum(map(k -> wᵁ⁺ᴸ[i, k], filter(k -> k != i, 1:n)))
                ∑ₖwₖᵁⁱ⁺ᵁ = sum(map(k -> wᵁ⁺ᵁ[i, k], filter(k -> k != i && k != j, 1:n)))
                @constraint(model, wⱼᵁⁱ⁺ᴸ + wᵢᵁ⁺ + ∑ₖwₖᵁⁱ⁺ᵁ ≥ 1)
                @constraint(model, wⱼᵁⁱ⁺ᵁ + ∑ₖwₖᵁⁱ⁺ᴸ ≤ 1)

                aᵢⱼᴸ = inf(A[i, j])
                aᵢⱼᵁ = sup(A[i, j])

                @constraint(model, wᵢᴸ⁻ ≤ aᵢⱼᴸ * wⱼᵁ⁻)
                @constraint(model, wᵢᵁ⁻ ≥ aᵢⱼᵁ * wⱼᴸ⁻)
                @constraint(model, wᵢᴸ⁺ ≥ aᵢⱼᴸ * wⱼᵁ⁺)
                @constraint(model, wᵢᵁ⁺ ≤ aᵢⱼᵁ * wⱼᴸ⁺)
            end
        end

        @objective(model, Min, sum(wᴸ⁻) - sum(wᴸ⁺) + sum(wᵁ⁺) - sum(wᵁ⁻))

        optimize!(model)

        optimalValue = sum(value.(wᴸ⁻)) - sum(value.(wᴸ⁺)) + sum(value.(wᵁ⁺)) - sum(value.(wᵁ⁻))

        ŵᴸ⁻ = correctPrecisionLoss(value.(wᴸ⁻), value.(wᴸ⁺))
        ŵᵁ⁻ = correctPrecisionLoss(value.(wᵁ⁻), value.(ŵᴸ⁻))
        ŵᵁ⁺ = correctPrecisionLoss(value.(wᵁ⁺), value.(ŵᵁ⁻))

        return (
            wᴸ⁺=value.(wᴸ⁺), wᴸ⁻=ŵᴸ⁻,
            wᵁ⁻=ŵᵁ⁻, wᵁ⁺=ŵᵁ⁺,
            optimalValue=optimalValue
        )
    finally
        empty!(model)
    end
end


function TFIWs_either(
    𝒜::Matrix{TwofoldInterval{T}}
) where {T<:Real}
    if !isTwofoldIntervalPCM(𝒜)
        throw(ArgumentError("Given matrix is not valid as a twofold interval matrix."))
    end

    ε = 1e-12
    n = size(𝒜, 1)

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    try
        @variable(model, wᴸ⁻[i=1:n] ≥ ε)
        @variable(model, wᵁ⁻[i=1:n] ≥ ε)
        @variable(model, wᴸ⁺[i=1:n] ≥ ε)
        @variable(model, wᵁ⁺[i=1:n] ≥ ε)
        @variable(model, wᴸ⁻ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᴸ⁻ᵁ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᴸ⁺ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᴸ⁺ᵁ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁻ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁻ᵁ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁺ᴸ[i=1:n, j=1:n] ≥ ε)
        @variable(model, wᵁ⁺ᵁ[i=1:n, j=1:n] ≥ ε)

        for i = 1:n
            wᵢᴸ⁻ = wᴸ⁻[i]
            wᵢᵁ⁻ = wᵁ⁻[i]
            wᵢᴸ⁺ = wᴸ⁺[i]
            wᵢᵁ⁺ = wᵁ⁺[i]
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᴸ⁻ ≤ wᵢᵁ⁻)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᵁ⁺)

            wᵢᴸⁱ⁻ᵁ = wᴸ⁻ᵁ[i, i]
            wᵢᴸⁱ⁺ᵁ = wᴸ⁺ᵁ[i, i]
            wᵢᵁⁱ⁻ᴸ = wᵁ⁻ᴸ[i, i]
            wᵢᵁⁱ⁺ᴸ = wᵁ⁺ᴸ[i, i]
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᵁⁱ⁻ᴸ)
            @constraint(model, wᵢᵁⁱ⁻ᴸ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᵁⁱ⁺ᴸ)
            @constraint(model, wᵢᵁⁱ⁺ᴸ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᴸⁱ⁻ᵁ)
            @constraint(model, wᵢᴸⁱ⁻ᵁ ≤ wᵢᵁ⁺)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᴸⁱ⁺ᵁ)
            @constraint(model, wᵢᴸⁱ⁺ᵁ ≤ wᵢᵁ⁺)

            ∑ⱼwⱼᴸⁱ⁻ᴸ = sum(map(j -> wᴸ⁻ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᴸⁱ⁻ᵁ = sum(map(j -> wᴸ⁻ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᴸ⁻ + ∑ⱼwⱼᴸⁱ⁻ᵁ ≥ 1)
            @constraint(model, wᵢᴸⁱ⁻ᵁ + ∑ⱼwⱼᴸⁱ⁻ᴸ ≤ 1)

            ∑ⱼwⱼᴸⁱ⁺ᴸ = sum(map(j -> wᴸ⁺ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᴸⁱ⁺ᵁ = sum(map(j -> wᴸ⁺ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᴸ⁺ + ∑ⱼwⱼᴸⁱ⁺ᵁ ≥ 1)
            @constraint(model, wᵢᴸⁱ⁺ᵁ + ∑ⱼwⱼᴸⁱ⁺ᴸ ≤ 1)

            ∑ⱼwⱼᵁⁱ⁻ᴸ = sum(map(j -> wᵁ⁻ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᵁⁱ⁻ᵁ = sum(map(j -> wᵁ⁻ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᵁⁱ⁻ᴸ + ∑ⱼwⱼᵁⁱ⁻ᵁ ≥ 1)
            @constraint(model, wᵢᵁ⁻ + ∑ⱼwⱼᵁⁱ⁻ᴸ ≤ 1)

            ∑ⱼwⱼᵁⁱ⁺ᴸ = sum(map(j -> wᵁ⁺ᴸ[i, j], filter(j -> i != j, 1:n)))
            ∑ⱼwⱼᵁⁱ⁺ᵁ = sum(map(j -> wᵁ⁺ᵁ[i, j], filter(j -> i != j, 1:n)))
            @constraint(model, wᵢᵁⁱ⁺ᴸ + ∑ⱼwⱼᵁⁱ⁺ᵁ ≥ 1)
            @constraint(model, wᵢᵁ⁺ + ∑ⱼwⱼᵁⁱ⁺ᴸ ≤ 1)

            for j = 1:n
                if i == j
                    continue
                end

                wⱼᴸ⁻ = wᴸ⁻[j]
                wⱼᵁ⁻ = wᵁ⁻[j]
                wⱼᴸ⁺ = wᴸ⁺[j]
                wⱼᵁ⁺ = wᵁ⁺[j]

                wⱼᴸⁱ⁻ᴸ = wᴸ⁻ᴸ[i, j]
                wⱼᴸⁱ⁻ᵁ = wᴸ⁻ᵁ[i, j]
                wⱼᴸⁱ⁺ᴸ = wᴸ⁺ᴸ[i, j]
                wⱼᴸⁱ⁺ᵁ = wᴸ⁺ᵁ[i, j]
                wⱼᵁⁱ⁻ᴸ = wᵁ⁻ᴸ[i, j]
                wⱼᵁⁱ⁻ᵁ = wᵁ⁻ᵁ[i, j]
                wⱼᵁⁱ⁺ᴸ = wᵁ⁺ᴸ[i, j]
                wⱼᵁⁱ⁺ᵁ = wᵁ⁺ᵁ[i, j]

                @constraint(model, wⱼᴸ⁺ ≤ wⱼᴸⁱ⁻ᴸ)
                @constraint(model, wⱼᴸⁱ⁻ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᴸ⁺ ≤ wⱼᴸⁱ⁺ᴸ)
                @constraint(model, wⱼᴸⁱ⁺ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᴸ⁺ ≤ wⱼᵁⁱ⁻ᴸ)
                @constraint(model, wⱼᵁⁱ⁻ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᴸ⁺ ≤ wⱼᵁⁱ⁺ᴸ)
                @constraint(model, wⱼᵁⁱ⁺ᴸ ≤ wⱼᴸ⁻)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᴸⁱ⁻ᵁ)
                @constraint(model, wⱼᴸⁱ⁻ᵁ ≤ wⱼᵁ⁺)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᴸⁱ⁺ᵁ)
                @constraint(model, wⱼᴸⁱ⁺ᵁ ≤ wⱼᵁ⁺)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᵁⁱ⁻ᵁ)
                @constraint(model, wⱼᵁⁱ⁻ᵁ ≤ wⱼᵁ⁺)
                @constraint(model, wⱼᵁ⁻ ≤ wⱼᵁⁱ⁺ᵁ)
                @constraint(model, wⱼᵁⁱ⁺ᵁ ≤ wⱼᵁ⁺)

                ∑ₖwₖᴸⁱ⁻ᴸ = sum(map(k -> wᴸ⁻ᴸ[i, k], filter(k -> k != i && k != j, 1:n)))
                ∑ₖwₖᴸⁱ⁻ᵁ = sum(map(k -> wᴸ⁻ᵁ[i, k], filter(k -> k != i, 1:n)))
                @constraint(model, wⱼᴸⁱ⁻ᴸ + ∑ₖwₖᴸⁱ⁻ᵁ ≥ 1)
                @constraint(model, wⱼᴸⁱ⁻ᵁ + wᵢᴸ⁻ + ∑ₖwₖᴸⁱ⁻ᴸ ≤ 1)

                ∑ₖwₖᴸⁱ⁺ᴸ = sum(map(k -> wᴸ⁺ᴸ[i, k], filter(k -> k != i && k != j, 1:n)))
                ∑ₖwₖᴸⁱ⁺ᵁ = sum(map(k -> wᴸ⁺ᵁ[i, k], filter(k -> k != i, 1:n)))
                @constraint(model, wⱼᴸⁱ⁺ᴸ + ∑ₖwₖᴸⁱ⁺ᵁ ≥ 1)
                @constraint(model, wⱼᴸⁱ⁺ᵁ + wᵢᴸ⁺ + ∑ₖwₖᴸⁱ⁺ᴸ ≤ 1)

                ∑ₖwₖᵁⁱ⁻ᴸ = sum(map(k -> wᵁ⁻ᴸ[i, k], filter(k -> k != i, 1:n)))
                ∑ₖwₖᵁⁱ⁻ᵁ = sum(map(k -> wᵁ⁻ᵁ[i, k], filter(k -> k != i && k != j, 1:n)))
                @constraint(model, wⱼᵁⁱ⁻ᴸ + wᵢᵁ⁻ + ∑ₖwₖᵁⁱ⁻ᵁ ≥ 1)
                @constraint(model, wⱼᵁⁱ⁻ᵁ + ∑ₖwₖᵁⁱ⁻ᴸ ≤ 1)

                ∑ₖwₖᵁⁱ⁺ᴸ = sum(map(k -> wᵁ⁺ᴸ[i, k], filter(k -> k != i, 1:n)))
                ∑ₖwₖᵁⁱ⁺ᵁ = sum(map(k -> wᵁ⁺ᵁ[i, k], filter(k -> k != i && k != j, 1:n)))
                @constraint(model, wⱼᵁⁱ⁺ᴸ + wᵢᵁ⁺ + ∑ₖwₖᵁⁱ⁺ᵁ ≥ 1)
                @constraint(model, wⱼᵁⁱ⁺ᵁ + ∑ₖwₖᵁⁱ⁺ᴸ ≤ 1)

                𝒜ᵢⱼ⁻ = inner(𝒜[i, j])
                aᵢⱼᴸ⁻ = inf(𝒜ᵢⱼ⁻)
                aᵢⱼᵁ⁻ = sup(𝒜ᵢⱼ⁻)
                𝒜ᵢⱼ⁺ = outer(𝒜[i, j])
                aᵢⱼᴸ⁺ = inf(𝒜ᵢⱼ⁺)
                aᵢⱼᵁ⁺ = sup(𝒜ᵢⱼ⁺)

                @constraint(model, wᵢᴸ⁻ ≤ aᵢⱼᴸ * wⱼᵁ⁻)
                @constraint(model, wᵢᵁ⁻ ≥ aᵢⱼᵁ * wⱼᴸ⁻)
                @constraint(model, wᵢᴸ⁺ ≥ aᵢⱼᴸ * wⱼᵁ⁺)
                @constraint(model, wᵢᵁ⁺ ≤ aᵢⱼᵁ * wⱼᴸ⁺)
            end
        end

        @objective(model, Min, sum(wᴸ⁻) - sum(wᴸ⁺) + sum(wᵁ⁺) - sum(wᵁ⁻))

        optimize!(model)

        optimalValue = sum(value.(wᴸ⁻)) - sum(value.(wᴸ⁺)) + sum(value.(wᵁ⁺)) - sum(value.(wᵁ⁻))

        ŵᴸ⁻ = correctPrecisionLoss(value.(wᴸ⁻), value.(wᴸ⁺))
        ŵᵁ⁻ = correctPrecisionLoss(value.(wᵁ⁻), value.(ŵᴸ⁻))
        ŵᵁ⁺ = correctPrecisionLoss(value.(wᵁ⁺), value.(ŵᵁ⁻))

        return (
            wᴸ⁺=value.(wᴸ⁺), wᴸ⁻=ŵᴸ⁻,
            wᵁ⁻=ŵᵁ⁻, wᵁ⁺=ŵᵁ⁺,
            optimalValue=optimalValue
        )
    finally
        empty!(model)
    end
end
