using Test

tests = [
    "timearray",
    "split",
    "apply",
    "broadcast",
    "combine",
    "modify",
    "meta",
    "readwrite",
    "timeseriesrc",
    "basemisc",
    "tables",
    "plotrecipes",
    "timeaxis/timegrod",
]


@testset "TimeSeries" begin
    @info("Running tests:")

    for test ∈ tests
        @info("\t* $test ...")
        include("$test.jl")
    end
end
