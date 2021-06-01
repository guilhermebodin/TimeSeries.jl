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

checkbounds(tg::TimeGrid{T,P,:infinite}, i::Real) where {T,P} =
    ((i < 1) && throw(BoundsError(tg, i)); nothing)
checkbounds(tg::TimeGrid{T,P,:finite}, i::Real) where {T,P} =
    (!(1 ≤ i ≤ tg.n) && throw(BoundsError(tg, i)); nothing)

function Base.getindex(tg::TimeGrid, i::Real)  # FIXME: is rounding acceptable?
    @boundscheck checkbounds(tg, i)
    ns = Nanosecond(round(Dates.value(Nanosecond(tg.p)) * (i - 1)))
    tg.o + ns
end

function Base.getindex(tg::TimeGrid, i::Integer)
    @boundscheck checkbounds(tg, i)
    tg.o + tg.p * (i - 1)
end

# TODO: isequal
# TODO: T is `Dates.Time` ?
for op in [:(==), :isequal]
    @eval function Base.findfirst(f::Base.Fix2{typeof($op)}, tg::TimeGrid{T,P,:finite}) where {T,P}
        x = convert(T, f.x)
        (tg.o ≤ x ≤ tg[end]) || return nothing
        Δ = Dates.value(Nanosecond(x - tg.o))
        p = periodnano(tg)
        iszero(Δ % p) || return nothing
        Δ ÷ p + 1
    end
end


###############################################################################
#  Private utils
###############################################################################

periodnano(tg::TimeGrid) = Dates.value(Nanosecond(tg.p))
