struct TimeGrid{T,P,L} <: AbstractTimeAxis{T}
    o::T   # start
    p::P   # period
    n::Int # length, if n == 0, indicate it's endless

    function TimeGrid{T,P,true}(o, p, n) where {T,P}  # the fininte one
        o′ = convert(T, o)
        n′ = convert(Int, n)
        p′ = convert(P, p)

        (n′ < 0) && throw(DomainError(n′))
        new(o′, p′, n′)
    end

    function TimeGrid{T,P,false}(o, p) where {T,P}  # the infinite one
        o′ = convert(T, o)
        p′ = convert(P, p)

        new(o′, p′, 0)
    end
end

# TODO: P should be a Dates.FixedPeriod?

TimeGrid(o::T, p::P) where {T,P}             = TimeGrid{T,P,false}(o, p)
TimeGrid(o::T, p::P, n::Integer) where {T,P} = TimeGrid{T,P,true}(o, p, n)

# TODO: constructor from range


###############################################################################
#  Iterator interfaces
###############################################################################

@generated function Base.iterate(tg::TimeGrid, s = 1)
    stop_expr = (!tg.parameters[3]) ? :() : :((s > tg.n) && return nothing)

    quote
        $stop_expr
        (tg.o + (s - 1) * tg.p, s + 1)  # FIXME: different state design to reduce * operation?
    end
end

Base.IteratorSize(::Type{TimeGrid{T,P,false}}) where {T,P} = Base.IsInfinite()
Base.IteratorSize(::Type{TimeGrid{T,P,true}}) where {T,P}  = Base.HasLength()

Base.IteratorEltype(::Type{<:TimeGrid}) = Base.HasEltype()
Base.eltype(::Type{<:TimeGrid{T}}) where T = T

Base.length(tg::TimeGrid{T,P,true}) where {T,P} = tg.n
Base.size(tg::TimeGrid{T,P,true}) where{T,P}    = tg.n
