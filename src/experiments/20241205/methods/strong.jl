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

LPResult = @NamedTuple{
    wᴸ⁺::Vector{T}, wᴸ⁻::Vector{T},
    wᵁ⁻::Vector{T}, wᵁ⁺::Vector{T},
    optimalValue::T
} where {T<:Real}

function TFIWs_strong(
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

        for i = 1:n
            wᵢᴸ⁻ = wᴸ⁻[i]
            wᵢᵁ⁻ = wᵁ⁻[i]
            wᵢᴸ⁺ = wᴸ⁺[i]
            wᵢᵁ⁺ = wᵁ⁺[i]
            @constraint(model, wᵢᴸ⁺ ≤ wᵢᴸ⁻)
            @constraint(model, wᵢᴸ⁻ ≤ wᵢᵁ⁻)
            @constraint(model, wᵢᵁ⁻ ≤ wᵢᵁ⁺)

            for j = 1:n
                if i == j
                    continue
                end

                αᵢⱼᴸ = inf(A[i, j])
                αᵢⱼᵁ = sup(A[i, j])
                wⱼᴸ⁻ = wᴸ⁻[j]
                wⱼᵁ⁻ = wᵁ⁻[j]
                wⱼᴸ⁺ = wᴸ⁺[j]
                wⱼᵁ⁺ = wᵁ⁺[j]

                @constraint(model, wᵢᴸ⁻ ≤ αᵢⱼᴸ * wⱼᵁ⁻)
                @constraint(model, wᵢᵁ⁻ ≥ αᵢⱼᵁ * wⱼᴸ⁻)
                @constraint(model, wᵢᴸ⁺ ≥ αᵢⱼᴸ * wⱼᵁ⁺)
                @constraint(model, wᵢᵁ⁺ ≤ αᵢⱼᵁ * wⱼᴸ⁺)
            end

            ∑wⱼᴸ⁻ = sum(map(j -> wᴸ⁻[j], filter(j -> i != j, 1:n)))
            @constraint(model, ∑wⱼᴸ⁻ + wᵢᵁ⁺ ≤ 1)
            ∑wⱼᵁ⁻ = sum(map(j -> wᵁ⁻[j], filter(j -> i != j, 1:n)))
            @constraint(model, ∑wⱼᵁ⁻ + wᵢᴸ⁺ ≥ 1)
        end

        # @constraint(model, sum(wᴸ⁺) + sum(wᵁ⁺) == 2)

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
