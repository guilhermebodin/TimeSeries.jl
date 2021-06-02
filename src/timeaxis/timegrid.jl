struct TimeGrid{T,P,L} <: AbstractTimeAxis{T}
    o::T    # start
    p::P    # period
    n::Int  # length, if n == 0, indicate it's endless

    function TimeGrid{T,P,:finite}(o, p, n) where {T,P}
        o′ = convert(T, o)
        n′ = convert(Int, n)
        p′ = convert(P, p)

        (n′ < 1) && throw(DomainError(n′))
        new(o′, p′, n′)
    end

    function TimeGrid{T,P,:infinite}(o, p) where {T,P}
        o′ = convert(T, o)
        p′ = convert(P, p)

        new(o′, p′, 0)
    end
end

# TODO: P should be a Dates.FixedPeriod?
# TODO: handle T is `Dates.Time` ?
# TODO: convert type `T` to indicate getindex output type, e.g. Date -> DateTime with Minute period
TimeGrid(o::T, p::P) where {T,P}             = TimeGrid{T,P,:infinite}(o, p)
TimeGrid(o::T, p::P, n::Integer) where {T,P} = TimeGrid{T,P,:finite}(o, p, n)

# TODO: constructor from range


###############################################################################
#  Iterator interfaces
###############################################################################

@generated function Base.iterate(tg::TimeGrid{T,P,L}, s = 1) where {T,P,L}
    quote
        $((L ≡ :infinite) ? :() : :((s > tg.n) && return nothing))
        (tg[s], s + 1)  # FIXME: different state design to reduce * operation?
    end
end

Base.IteratorSize(::Type{TimeGrid{T,P,:infinite}}) where {T,P} = Base.IsInfinite()
Base.IteratorSize(::Type{TimeGrid{T,P,:finite}}) where {T,P}   = Base.HasLength()

Base.IteratorEltype(::Type{<:TimeGrid}) = Base.HasEltype()
Base.eltype(::Type{<:TimeGrid{T}}) where T = T

Base.length(tg::TimeGrid{T,P,:finite}) where {T,P} = tg.n
Base.size(tg::TimeGrid{T,P,:finite}) where{T,P}    = tg.n


###############################################################################
#  Indexing
###############################################################################

function Base.getindex(tg::TimeGrid, i::Real)  # FIXME: is rounding acceptable?
    @boundscheck checkbounds(tg, i)
    ns = Nanosecond(round(Dates.value(Nanosecond(tg.p)) * (i - 1)))
    tg.o + ns
end

function Base.getindex(tg::TimeGrid, i::Integer)
    @boundscheck checkbounds(tg, i)
    tg.o + tg.p * (i - 1)
end

const LessOrLessEq       = Union{Base.Fix2{typeof(≤)}, Base.Fix2{typeof(<)}}
const GreaterOrGreaterEq = Union{Base.Fix2{typeof(≥)}, Base.Fix2{typeof(>)}}
const EqOrIsEq           = Union{Base.Fix2{typeof(==)},Base.Fix2{typeof(isequal)}}

# TODO: T is `Dates.Time` ?
for op in [:(==), :isequal]
    @eval function Base.findfirst(f::Base.Fix2{typeof($op)}, tg::TimeGrid{T}) where T
        x = convert(T, f.x)
        isinbounds(tg, x) || return nothing
        time2idx(tg, x)
    end

    @eval Base.findlast(f::Base.Fix2{typeof($op)}, tg::TimeGrid) = findfirst(f, tg)
end

function Base.findprev(f::EqOrIsEq, tg::TimeGrid{T}, i) where T
    @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))

    x = convert(T, f.x)
    isinbounds(tg, x) || return nothing
    (x ≤ tg[i]) || return nothing
    time2idx(tg, x)
end

@generated function Base.findprev(f::LessOrLessEq, tg::TimeGrid{T}, i) where T

    j = (f.parameters[1] ≡ typeof(<)) ? :(iszero(Δ % p)) : :(0)

    quote
        @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))

        x = convert(T, f.x)
        isinbounds(tg, x) || return nothing
        Δ = periodnano(x - tg.o)
        p = periodnano(tg)
        min(Δ ÷ p + 1 - $j, i)
    end
end

function Base.findprev(f::GreaterOrGreaterEq, tg::TimeGrid, i)
    @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))
    ifelse(f(tg[i]), i, nothing)
end



###############################################################################
#  Private utils
###############################################################################

isinbounds(tg::TimeGrid{T,P,:infinite}, i::Real) where {T,P} = (1 ≤ i)
isinbounds(tg::TimeGrid{T,P,:finite},   i::Real) where {T,P} = (1 ≤ i ≤ tg.n)
isinbounds(tg::TimeGrid{T,P,:infinite}, t::TimeType) where {T,P} = (tg.o ≤ t)
isinbounds(tg::TimeGrid{T,P,:finite},   t::TimeType) where {T,P} = (tg.o ≤ t ≤ tg[end])

checkbounds(tg::TimeGrid, i::Real) =
    (isinbounds(tg, i) || throw(BoundsError(tg, i)); nothing)

periodnano(t::Period)    = Dates.value(Nanosecond(t))
periodnano(tg::TimeGrid) = periodnano(tg.p)

function time2idx(tg::TimeGrid, t)
    Δ = periodnano(t - tg.o)
    p = periodnano(tg)
    iszero(Δ % p) || return nothing
    Δ ÷ p + 1
end
