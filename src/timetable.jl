###############################################################################
#  Type
###############################################################################

mutable struct TimeTable{T<:AbstractTimeAxis} <: AbstractTimeSeries{T}
    ta::T
    vecs::OrderedDict{Symbol,AbstractVector}
    n::Int  # length, in case of infinte time axis

    function TimeTable{T}(ta::T, vecs) where {T}
        m = mapreduce(length, max, values(vecs))
        n = if Base.haslength(T)
            n′ = length(ta)
            (n′ ≥ m) || throw(DimensionMismatch(
                "The vector length should less or equal than the one of time axis"))
            n′
        else
            m
        end

        # note that it will copy, if the length of a col is shorter than `m`
        for (k, v) in vecs
            (length(v) == n) && continue
            vecs[k] = collect(PaddedView(missing, v, (n,)))
        end

        new(ta, vecs, n)
    end
    # other design style:
    #   colnames::Vector{Symbol}
    #   cols::Vector{AbstractVector}
end

TimeTable(ta::T, vecs::OrderedDict{Symbol}) where T = TimeTable{T}(ta, vecs)
function TimeTable(ta::T; kw...) where T
    vecs = OrderedDict{Symbol,AbstractVector}()
    for (k, v) ∈ kw
        vecs[k] = v
    end
    TimeTable(ta, vecs)
end

const TimeTableTimeCol = :time

struct TimeTableRow{T,V}
    i::Int
    t::T
    v::V
end


###############################################################################
#  Indexing
###############################################################################

Base.lastindex(tt::TimeTable) = getfield(tt, :n)

Base.checkindex(::Type{Bool}, tt::TimeTable, i::Int) = (1 ≤ i ≤ lastindex(tt))

Base.getindex(tt::TimeTable, s::Symbol) =
    (s ≡ TimeTableTimeCol) ? getfield(tt, :ta) : getvec(tt, s)

function Base.getindex(tt::TimeTable, i::Int)
    @boundscheck checkbounds(tt, i)
    TimeTableRow(i, _ta(tt)[i], map(x -> x[i], values(_vecs(tt))))
end

Base.getindex(tt::TimeTable, t::TimeType) = tt[time2idx(tt, t)]
Base.getindex(tt::TimeTable, i::Int, s::Symbol) =
    (@boundscheck checkbounds(tt, i); (s ≡ TimeTableTimeCol) ? _ta(tt)[i] : _vecs(tt)[s][i])
Base.getindex(tt::TimeTable, t::TimeType, s::Symbol) = tt[time2idx(tt, t), s]

for func ∈ [:findfirst, :findlast]
    @eval function Base.$func(f::Function, tt::TimeTable)
        i = $func(f, _ta(tt))
        isnothing(i) && return nothing
        ifelse(i > getfield(tt, :n), nothing, i)
    end

    # TODO: handle case of infinte timegrid for findlast
end

for func ∈ [:findprev, :findnext]
    @eval function Base.$func(f::Function, tt::TimeTable, j::Int)
        i = $func(f, _ta(tt), j)
        isnothing(i) && return nothing
        ifelse(i > getfield(tt, :n), nothing, i)
    end
end

function Base.getindex(r::TimeTableRow, i::Int)
    (i == 1) ? r.i :
    (i == 2) ? r.t :
    (i == 3) ? r.v :
    throw(BoundsError(r, i))
end

###############################################################################
#  Modification
###############################################################################

# TODO: support time axis modification
Base.setindex!(tt::TimeTable, v, i::Int, s::Symbol) =
    (@boundscheck checkbounds(tt, i); _vecs(tt)[s][i] = v)
Base.setindex!(tt::TimeTable, v, t::TimeType, s::Symbol) = (tt[time2idx(tt, t), s] = v)

function Base.resize!(tt::TimeTable, n::Int)
    for v ∈ values(_vecs(tt))
        resize!(v, n)
    end
    setfield!(tt, :n, n)
    tt
end


###############################################################################
#  Private utils
###############################################################################


checkbounds(tt::TimeTable, i::Int) =
    (checkindex(Bool, tt, i) || throw(BoundsError(tt, i)); nothing)

@inline getvec(tt::TimeTable, s::Symbol) = _vecs(tt)[s]
@inline _vecs(tt::TimeTable) = getfield(tt, :vecs)
@inline _ta(tt::TimeTable) = getfield(tt, :ta)

@inline time2idx(tt::TimeTable, t::TimeType) = _ta(tt)[t]
