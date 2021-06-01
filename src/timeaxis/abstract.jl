abstract type AbstractTimeAxis{T} <: AbstractVector{T} end


###############################################################################
#  Printing
###############################################################################

Base.summary(io::IO, ata::AbstractTimeAxis) = print(io, typeof(ata))
Base.show(io::IO, ::MIME{Symbol("text/plain")}, ata::AbstractTimeAxis) = summary(io, ata)
