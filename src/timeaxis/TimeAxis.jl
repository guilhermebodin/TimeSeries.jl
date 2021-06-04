module TimeAxis

using Dates
using IntervalSets

###############################################################################
#  export
###############################################################################

export AbstractTimeAxis
export TimeGrid
export resample

###############################################################################
#  include
###############################################################################

include("./abstract.jl")
include("./timegrid.jl")

end  # module TimeAxis
