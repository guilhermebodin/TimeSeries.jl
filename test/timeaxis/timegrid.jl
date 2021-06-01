using Base.Iterators
using Dates
using Test

using TimeSeries.TimeAxis


@testset "TimeGrid" begin


@testset "iterator" begin
    @testset "finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 3)
        @test [i for i ∈ tg] == [
            DateTime(2021, 1, 1, 0,  0),
            DateTime(2021, 1, 1, 0, 15),
            DateTime(2021, 1, 1, 0 ,30),
        ]
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @test [i for i ∈ take(tg, 3)] == [
            DateTime(2021, 1, 1, 0,  0),
            DateTime(2021, 1, 1, 0, 15),
            DateTime(2021, 1, 1, 0 ,30),
        ]
        @test length([i for i ∈ take(tg, 4202)]) == 4202
    end
end  # @testset "iterator"


@testset "getindex" begin
    @testset "finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @test_throws BoundsError tg[0]
        @test_throws BoundsError tg[11]
        @test_throws BoundsError tg[-42]
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @test tg[1] == DateTime(2021, 1, 1)
        @test_throws BoundsError tg[0]
        @test_throws BoundsError tg[-42]
    end
end   # @testset "getindex"


end  # @testset "TimeGrid"
