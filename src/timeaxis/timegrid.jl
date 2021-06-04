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
TimeGrid(o::T, p::P, n::Integer) where {T,P} = TimeGrid{T,P,:finite}(o, p, n)
TimeGrid(o::T, p::P) where {T,P}             = TimeGrid{T,P,:infinite}(o, p)

TimeGrid(tg::TimeGrid{T,P,:infinite}; o = tg.o, p = tg.p) where {T,P} =
    TimeGrid(o, p)
TimeGrid(tg::TimeGrid{T,P,:finite}; o = tg.o, p = tg.p, n = tg.n) where {T,P} =
    TimeGrid(o, p, n)

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

function Base.getindex(tg::TimeGrid, t::TimeType)
    @boundscheck checkbounds(tg, t)
    i = time2idx(tg, t)
    isnothing(i) ? (throw(KeyError(t))) : i
end

const LessOrLessEq       = Union{Base.Fix2{typeof(≤)}, Base.Fix2{typeof(<)}}
const GreaterOrGreaterEq = Union{Base.Fix2{typeof(≥)}, Base.Fix2{typeof(>)}}
const EqOrIsEq           = Union{Base.Fix2{typeof(==)},Base.Fix2{typeof(isequal)}}

Base.findfirst(f::Function, tg::TimeGrid) = findnext(f, tg, 1)

Base.findlast(f::Function, tg::TimeGrid{T,P,:finite}) where {T,P} =
    findprev(f, tg, lastindex(tg))
Base.findlast(f::EqOrIsEq, tg::TimeGrid{T,P,:infinite}) where {T,P} =
    findnext(f, tg, 1)
Base.findlast(f::LessOrLessEq, tg::TimeGrid{T,P,:infinite}) where {T,P} =
    findprev(f, tg, typemax(Int))
Base.findlast(f::GreaterOrGreaterEq, tg::TimeGrid{T,P,:infinite}) where {T,P} =
    throw(DomainError("infinite iterator. Please use `findprev` instead"))

function Base.findall(f::EqOrIsEq, tg::TimeGrid)
    x = findfirst(f, tg)
    isnothing(x) && return Int[]
    Int[x]
end

function Base.findall(f::LessOrLessEq, tg::TimeGrid)
    x = findlast(f, tg)
    isnothing(x) && return Int[]
    1:x
end

function Base.findall(f::GreaterOrGreaterEq, tg::TimeGrid)
    x = findfirst(f, tg)
    isnothing(x) && return Int[]
    x:lastindex(tg)
end

function Base.findnext(f::EqOrIsEq, tg::TimeGrid{T}, i) where T
    @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))
    x = convert(T, f.x)
    isinbounds(tg, x) || return nothing
    (x < tg[i]) && return nothing
    time2idx(tg, x)
end

function Base.findnext(f::LessOrLessEq, tg::TimeGrid, i)
    @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))
    ifelse(f(tg[i]), i, nothing)
end

@generated function Base.findnext(f::GreaterOrGreaterEq, tg::TimeGrid{T}, i) where T
    func = f.parameters[1]
    op = (func ≡ typeof(>)) ? :(≥) : :(>)
    boundary_cond = Base.haslength(tg) ? :($op(x,tg[end]) && return nothing) : :()
    j = (f.parameters[1] ≡ typeof(>)) ? :(1) : :(Int(!iszero(Δ % p)))

    quote
        @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))
        x = convert(T, f.x)
        $boundary_cond
        f(tg[i]) && return i
        Δ = periodnano(x - tg[i])
        p = periodnano(tg)
        Δ ÷ p + i + $j
    end
end

function Base.findprev(f::EqOrIsEq, tg::TimeGrid{T}, i) where T
    @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))

    x = convert(T, f.x)
    isinbounds(tg, x) || return nothing
    (x ≤ tg[i]) || return nothing
    time2idx(tg, x)
end

@generated function Base.findprev(f::LessOrLessEq, tg::TimeGrid{T}, i) where T
    func = f.parameters[1]
    cond = (func ≡ typeof(<)) ? :((x ≤ tg.o)) : :((x < tg.o))
    j = (func ≡ typeof(<)) ? :(iszero(Δ % p)) : :(0)

    quote
        @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))
        x = convert(T, f.x)
        $cond && return nothing
        Δ = periodnano(x - tg.o)
        p = periodnano(tg)
        min(Δ ÷ p + 1 - $j, i)
    end
end

function Base.findprev(f::GreaterOrGreaterEq, tg::TimeGrid, i)
    @boundscheck isinbounds(tg, i) || throw(BoundsError(tg, i))
    ifelse(f(tg[i]), i, nothing)
end

# TODO: find function with NSS
# TODO: support find*(in(::Interval), tg)


###############################################################################
#  Relative Time
###############################################################################

Base.getindex(tg::TimeGrid, ::typeof(+), n::Int) =  Nanosecond(tg.p) * n
Base.getindex(tg::TimeGrid, ::typeof(-), n::Int) = -Nanosecond(tg.p) * n

# TODO: test cases
function Base.getindex(tg::TimeGrid, ::typeof(+), p::Period)
    p′ = periodnano(p)
    q = periodnano(tg.p)
    iszero(p′ % q) || throw(KeyError(p))
    p′ ÷ q + 1
end

Base.:+(tg::TimeGrid, i::Real)   = TimeGrid(tg, o = tg.o + Nanosecond(tg.p))
Base.:-(tg::TimeGrid, i::Real)   = TimeGrid(tg, o = tg.o - Nanosecond(tg.p))
Base.:+(tg::TimeGrid, p::Period) = TimeGrid(tg, o = tg.o + p)
Base.:-(tg::TimeGrid, p::Period) = TimeGrid(tg, o = tg.o - p)


###############################################################################
#  SubVector
###############################################################################

Base.view(tg::TimeGrid, r::OrdinalRange{Int,Int}) =
    TimeGrid(tg[first(r)], tg.p * step(r), length(r))

Base.view(tg::TimeGrid, i::ClosedInterval{Int}) =
    TimeGrid(tg[leftendpoint(i)], tg.p, length(i))


###############################################################################
#  Reduction
###############################################################################

function Base.count(i::Interval{:closed,:closed}, tg::TimeGrid)
    x = findfirst(≥(leftendpoint(i)), tg)
    isnothing(x) && return 0
    y = findlast(≤(rightendpoint(i)), tg)
    isnothing(y) && return 0
    abs(y - x) + 1
end


###############################################################################
#  Resampling
###############################################################################

resample(tg::TimeGrid, i::Real) = TimeGrid(tg, p = Nanosecond(tg.p) * i)
resample(tg::TimeGrid, p::Period) = TimeGrid(tg, p = p)


###############################################################################
#  Searching between two point processes
###############################################################################

function Base.findall(tg::TimeGrid{T,P,:finite}, tg′::TimeGrid) where {T,P}
    # FIXME: this is a naive implementation
    A = Vector{Union{Int,Missing}}(undef, tg.n)
    @simd for i ∈ 1:tg.n
        t = tg[i]
        j = findfirst(==(t), tg′)
        A[i] = ifelse(isnothing(j), missing, j)
    end
    A
end


###############################################################################
#  Common vector operations
###############################################################################

#TODO: diff

###############################################################################
#  Private utils
###############################################################################

isinbounds(tg::TimeGrid{T,P,:infinite}, i::Real) where {T,P} = (1 ≤ i)
isinbounds(tg::TimeGrid{T,P,:finite},   i::Real) where {T,P} = (1 ≤ i ≤ tg.n)
isinbounds(tg::TimeGrid{T,P,:infinite}, t::TimeType) where {T,P} = (tg.o ≤ t)
isinbounds(tg::TimeGrid{T,P,:finite},   t::TimeType) where {T,P} = (tg.o ≤ t ≤ tg[end])

checkbounds(tg::TimeGrid, i::Real) =
    (isinbounds(tg, i) || throw(BoundsError(tg, i)); nothing)
checkbounds(tg::TimeGrid, i::TimeType) =
    (isinbounds(tg, i) || throw(KeyError(i)); nothing)

periodnano(t::Period)    = Dates.value(Nanosecond(t))
periodnano(tg::TimeGrid) = periodnano(tg.p)

function time2idx(tg::TimeGrid, t)
    Δ = periodnano(t - tg.o)
    p = periodnano(tg)
    iszero(Δ % p) || return nothing
    Δ ÷ p + 1
end
