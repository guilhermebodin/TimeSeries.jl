abstract type AbstractTimeAxis{T} <: AbstractVector{T} end


###############################################################################
#  Indexing
###############################################################################

Base.axes(ata::AbstractTimeAxis) = (Base.OneTo(length(ata)),)


###############################################################################
#  Printing
###############################################################################

Base.summary(io::IO, ata::AbstractTimeAxis) = print(io, typeof(ata))
Base.show(io::IO, ::MIME{Symbol("text/plain")}, ata::AbstractTimeAxis) = summary(io, ata)


###############################################################################
#  Order-related
###############################################################################
# https://docs.julialang.org/en/v1/base/sort/#Order-Related-Functions

Base.issorted(ata::AbstractTimeAxis; rev::Bool = false) = !rev


###############################################################################
#  Resampling
###############################################################################

function resample end
function resample! end
