module MatrixParser

using DataFrames
using IntervalArithmetic

include("../../ahp/twofold_interval/v1/twofold_interval.jl")
using .TwofoldIntervalArithmetic

include("crisp.jl")
using .CrispTable

include("interval.jl")
using .IntervalTable

include("twofold_interval.jl")
using .TwofoldIntervalTable

function parseMatrixData(
    data::DataFrameRow
)::Union{
    AbstractMatrix{Float64},
    AbstractVector{Float64},
    AbstractMatrix{Interval{Float64}},
    AbstractVector{Interval{Float64}},
    AbstractMatrix{TwofoldInterval{Float64}},
    AbstractVector{TwofoldInterval{Float64}},
}
    type = data[:type]

    if type == "crisp_matrix" || type == "crisp_vector"
        return parseCrispData(data)
    end

    if type == "interval_matrix" || type == "interval_vector"
        return parseIntervalData(data)
    end

    if type == "twofold_interval_matrix" || type == "twofold_interval_vector"
        return parseTwofoldIntervalData(data)
    end

    error("Unknown data type: $type")
end

export parseMatrixData

end
