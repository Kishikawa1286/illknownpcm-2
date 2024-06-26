# This file is auto-generated from crisp_pcm.jmd.
# Do not edit this file manually.

module CrispPCM

using LinearAlgebra

include("../../nearly_equal/v1/nearly_equal.jl")
using .NearlyEqual

"""
    isCrispPCM(A)

Check if the matrix `A` is a crisp PCM.
"""
@inline function isCrispPCM(A::Matrix{T})::Bool where {T <: Real}
    m, n = size(A)
    # Check if the matrix is square
    if m != n return false end

    for i in 1:n
        for j in (i+1):n
            aᵢⱼ = A[i, j]; aⱼᵢ = A[j, i]
            # Check if the elements are positive
            if aᵢⱼ ≤ 0 || aⱼᵢ ≤ 0 return false end
            # Check reciprocity
            if !isNearlyEqual(aᵢⱼ, 1/aⱼᵢ) return false end
        end
    end

    # Check if the diagonal elements are 1
    for i in 1:n
        aᵢᵢ = A[i, i]
        if aᵢᵢ != 1 return false end
    end

    return true
end

export isCrispPCM

"""
    CI(A)

Calculate the Consistency Index of the crisp PCM `A`.
Throws an `ArgumentError` if `A` is not a crisp PCM.
"""
@inline function CI(A::Matrix{T})::Real where {T <: Real}
    if (!isCrispPCM(A))
        throw(ArgumentError("A must be crisp PCM"))
    end

    n = size(A, 2)
    λₘₐₓ = maximum(real.(filter(λ  -> isreal(λ), eigvals(A))))
    return (λₘₐₓ - n) / (n - 1)
end

"""
    CR(A)

Calculate the Consistency Ratio of the crisp PCM `A`.
Throws an `ArgumentError` if `A` is not a crisp PCM.
"""
@inline function CR(A::Matrix{T})::Real where {T <: Real}
    if (!isCrispPCM(A))
        throw(ArgumentError("A must be crisp PCM"))
    end

    n = size(A, 2)
    return CI(A) / RI(n)
end

"""
    RI(n)

Calculate the Random Index for the dimension `n` to calculate [`CR`](@ref).
Throws an `ArgumentError` if `n` is less than 3.
"""
function RI(n::Integer)::Real
    if n < 3
        throw(ArgumentError("n must be greater than or equal to 3"))
    end
    if n == 3
        return 0.58
    end
    if n == 4
        return 0.9
    end
    if n == 5
        return 1.12
    end
    if n == 6
        return 1.24
    end
    if n == 7
        return 1.32
    end
    if n == 8
        return 1.41
    end
    if n == 9
        return 1.45
    end
    if n >= 10
        return 1.49
    end
end

export CI, CR, RI

"""
    PCM(W)

Generate a crisp PCM from the weight vector `W`.
Throws an `ArgumentError` if `W` is not a positive vector.
"""
function PCM(W::Vector{T})::Matrix{T} where {T <: Real}
    if any(w -> w ≤ 0, W)
        throw(ArgumentError("W must be positive"))
    end

    n = length(W)
    A = Matrix{T}(undef, n, n)

    for i in 1:n, j in 1:n
        wᵢ = W[i]; wⱼ = W[j]
        aᵢⱼ = wᵢ / wⱼ
        A[i, j] = aᵢⱼ
    end

    return A
end

export PCM

end
