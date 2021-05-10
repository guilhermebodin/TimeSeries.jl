struct TimeGrid{T,F<:Real,P} <: AbstractTimeAxis{T}
    start::T
    stop::Int
    p::P
end

# TODO: P should be a Dates.FixedPeriod?

# TimeGrid(::)
