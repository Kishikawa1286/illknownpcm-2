# This file is auto-generated from interval_pcm.jmd.
# Do not edit this file manually.

module IntervalPCM

using IntervalArithmetic
using IntervalArithmetic.Symbols

include("../../nearly_equal/v1/nearly_equal.jl")
using .NearlyEqual

include("../../crisp_pcm/v1/crisp_pcm.jl")
using .CrispPCM

include("../../interval_weight_vector/v1/interval_weight_vector.jl")
using .IntervalWeightVector
import .IntervalWeightVector: ∈, ∋

include("../../interval/v1/interval.jl")
using .ExtendedIntervalArithmetic
import .ExtendedIntervalArithmetic: Sim, Inc

"""
    isIntervalPCM(A; allow_uncommon=false)

Check whether the given matrix `A` is an interval PCM.
"""
@inline function isIntervalPCM(
    A::Matrix{Interval{T}};
    allow_uncommon::Bool = false,
    strict::Bool = false
)::Bool where {T <: Real}
    tolerance = strict ? 1e-10 : 1e-6

    m, n = size(A)
    # Check if the matrix is square
    if m != n return false end

    for i = 1:n
        for j in (i+1):n
            if !iscommon(A[i,j])
                # non-common interval means like: ∅, (-∞, 1]
                if allow_uncommon
                    continue
                else
                    return false
                end
            end
            
            aᵢⱼᴸ = inf(A[i,j]); aᵢⱼᵁ = sup(A[i,j])
            aⱼᵢᴸ = inf(A[j,i]); aⱼᵢᵁ = sup(A[j,i])

            # Check if the lower bound is positive
            if aᵢⱼᴸ ≤ 0 || aⱼᵢᴸ ≤ 0 return false end

            # Check reciprocity
            if !isNearlyEqual(aᵢⱼᴸ, 1 / aⱼᵢᵁ; tolerance=tolerance) return false end
            if !isNearlyEqual(aᵢⱼᵁ, 1 / aⱼᵢᴸ; tolerance=tolerance) return false end
        end
    end

    # Check if the diagonal elements are [1, 1]
    for i in 1:n
        aᵢⱼᴸ = inf(A[i,i]); aᵢⱼᵁ = sup(A[i,i])
        if !isNearlyEqual(aᵢⱼᴸ, 1.0; tolerance=1e-10) return false end
        if !isNearlyEqual(aᵢⱼᵁ, 1.0; tolerance=1e-10) return false end
    end

    return true 
end

export isIntervalPCM

"""
    isincluded(A, B; strict = false)

Check whether the given interval PCM `B` contains the given crisp PCM `A`.
If `strict` is `true`, then the function returns `false` if `A` is not exactly equal to `B`.
Throws an `ArgumentError` if `A` is not a crisp PCM or `B` is not an interval PCM.
Throws a `DimensionMismatch` if the dimensions of `A` and `B` do not match.
"""
function isincluded(
    A::Matrix{T},
    B::Matrix{Interval{T}};
    strict::Bool = false
)::Bool where {T <: Real}
    if !isCrispPCM(A)
        throw(ArgumentError("The given matrix is not a crisp PCM."))
    end
    if !isIntervalPCM(B)
        throw(ArgumentError("The given matrix is not an interval PCM."))
    end

    if size(A) != size(B)
        throw(DimensionMismatch("The dimensions of the given matrices do not match."))
    end

    tolerance = strict ? 1e-10 : 1e-6

    n = size(A, 1)

    for i = 1:n, j = 1:n
        aᵢⱼ = A[i,j]; bᵢⱼᴸ = inf(B[i,j]); bᵢⱼᵁ = sup(B[i,j])

        if bᵢⱼᴸ ≤ aᵢⱼ && aᵢⱼ ≤ bᵢⱼᵁ continue end

        if strict return false end

        if !isNearlyEqual(aᵢⱼ, bᵢⱼᴸ; tolerance=tolerance) && !isNearlyEqual(aᵢⱼ, bᵢⱼᵁ; tolerance=tolerance)
            return false
        end
    end

    return true
end

"""
    ∈(A, B)

Unicode alias for `isincluded(A, B)`.
"""
∈(A::Matrix, B::Matrix{Interval})::Bool = isincluded(A, B)

"""
    ∋(B, A)

Unicode alias for `isincluded(A, B)`.
"""
∋(B::Matrix{Interval}, A::Matrix)::Bool = isincluded(A, B)

export isincluded, ∈, ∋

"""
    Sim(A, B)

Calculate the similarity between the given interval PCMs `A` and `B`.
Throws an `ArgumentError` if `A` is not an interval PCM or `B` is not an interval PCM.
Throws a `DimensionMismatch` if the dimensions of `A` and `B` do not match.
"""
function Sim(
    A::Matrix{Interval{T}},
    B::Matrix{Interval{T}}
)::Real where {T <: Real}
    if !isIntervalPCM(A; allow_uncommon=true)
        throw(ArgumentError("The given matrix A is not an interval PCM."))
    end
    if !isIntervalPCM(B; allow_uncommon=true)
        throw(ArgumentError("The given matrix B is not an interval PCM."))
    end
    if size(A) != size(B)
        throw(DimensionMismatch("The dimensions of the given matrices do not match."))
    end

    n = size(A, 1)
    sum = zero(T)
    for i = 1:n, j = 1:n
        if i ≥ j continue end
        Aᵢⱼ = A[i,j]; Bᵢⱼ = B[i,j]
        sum += Sim(Aᵢⱼ, Bᵢⱼ)
    end

    return 2 / (n * (n - 1)) * sum
end

export Sim

"""
    Inc(A, B)

Calculate the degree of A in B.
"""
function Inc(
    A::Matrix{Interval{T}},
    B::Matrix{Interval{T}}
)::Real where {T <: Real}
    if !isIntervalPCM(A; allow_uncommon=true)
        throw(ArgumentError("The given matrix A is not an interval PCM."))
    end
    if !isIntervalPCM(B; allow_uncommon=true)
        throw(ArgumentError("The given matrix B is not an interval PCM."))
    end
    if size(A) != size(B)
        throw(DimensionMismatch("The dimensions of the given matrices do not match."))
    end

    n = size(A, 1)
    sum = zero(T)
    for i = 1:n, j = 1:n
        if i ≥ j continue end
        Aᵢⱼ = A[i,j]; Bᵢⱼ = B[i,j]
        sum += Inc(Aᵢⱼ, Bᵢⱼ)
    end

    return 2 / (n * (n - 1)) * sum
end

export Inc

"""
    intervalPCM(W)

Generate an interval PCM from the interval weight vector `W`.
Throws an `ArgumentError` if `W` is not an interval weight vector.
"""
function intervalPCM(
    W::Vector{Interval{T}}
)::Matrix{Interval{T}} where {T <: Real}
    if !isIntervalWeightVector(W)
        throw(ArgumentError("The given vector is not an interval weight vector."))
    end

    n = length(W)
    A = Matrix{Interval{T}}(undef, n, n)
    
    for i = 1:n, j = 1:n
        if i == j
            A[i,j] = 1.0..1.0
            continue
        end

        Wᵢ = W[i]; Wⱼ = W[j]
        wᵢᴸ = inf(Wᵢ); wᵢᵁ = sup(Wᵢ)
        wⱼᴸ = inf(Wⱼ); wⱼᵁ = sup(Wⱼ)

        aᵢⱼᴸ = wᵢᴸ / wⱼᵁ; aᵢⱼᵁ = wᵢᵁ / wⱼᴸ
        A[i,j] = aᵢⱼᴸ..aᵢⱼᵁ
    end

    return A
end

export intervalPCM

end
