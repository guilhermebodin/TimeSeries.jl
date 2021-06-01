using Base.Iterators
using Dates
using Test

using TimeSeries.TimeAxis


@testset "TimeGrid" begin


@testset "iterator" begin
    @testset "finite iterator" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 3)
        @test [i for i ∈ tg] == [
            DateTime(2021, 1, 1, 0,  0),
            DateTime(2021, 1, 1, 0, 15),
            DateTime(2021, 1, 1, 0 ,30),
        ]
    end

    @testset "infinite iterator" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @test [i for i ∈ take(tg, 3)] == [
            DateTime(2021, 1, 1, 0,  0),
            DateTime(2021, 1, 1, 0, 15),
            DateTime(2021, 1, 1, 0 ,30),
        ]
        @test length([i for i ∈ take(tg, 4202)]) == 4202
    end

end  # @testset "iterator


end  # @testset "TimeGrid"
