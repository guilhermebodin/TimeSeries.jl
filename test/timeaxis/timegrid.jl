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
        @test tg[1]   == tg.o
        @test tg[2]   == DateTime(2021, 1, 1, 0, 15)
        @test tg[end] == tg.o + 9 * Minute(15)
        @test_throws BoundsError tg[0]
        @test_throws BoundsError tg[11]
        @test_throws BoundsError tg[-42]
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @test tg[1] == tg.o
        @test tg[2] == DateTime(2021, 1, 1, 0, 15)
        @test_throws BoundsError tg[0]
        @test_throws BoundsError tg[-42]
    end
end   # @testset "getindex"


@testset "find*" begin
    @testset "findprev finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        vg = collect(tg)

        # TODO: test cases for benchmarking against tg and vg

        for f ∈ [≤, <, ≥, >]
            @test findprev(f(DateTime(2021, 1, 1, 0, 33)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 33)), vg, 10)
            @test findprev(f(DateTime(2021, 1, 1, 0, 30)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 30)), vg, 10)
            @test findprev(f(DateTime(2021, 1, 1, 0, 29)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 29)), vg, 10)

            @test findprev(f(DateTime(2021, 1, 1, 0, 33)), tg,  3) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 33)), vg,  3)
            @test findprev(f(DateTime(2021, 1, 1, 0, 30)), tg,  3) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 30)), vg,  3)
            @test findprev(f(DateTime(2021, 1, 1, 0, 29)), tg,  3) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 29)), vg,  3)

            @test findprev(f(DateTime(2021, 1, 1, 0, 33)), tg,  2) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 33)), vg,  2)
            @test findprev(f(DateTime(2021, 1, 1, 0, 30)), tg,  2) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 30)), vg,  2)
            @test findprev(f(DateTime(2021, 1, 1, 0, 29)), tg,  2) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 29)), vg,  2)

            @test findprev(f(Date(2019, 1, 1)), tg,  2) ==
                  findprev(f(Date(2019, 1, 1)), vg,  2)
            @test findprev(f(Date(2019, 1, 1)), tg,  2) ==
                  findprev(f(Date(2019, 1, 1)), vg,  2)
            @test findprev(f(Date(2019, 1, 1)), tg,  2) ==
                  findprev(f(Date(2019, 1, 1)), vg,  2)

            @test_throws BoundsError findprev(f(DateTime(2021, 1, 1, 0, 33)), tg, 42)
        end
    end

    @testset "findprev, ≤, infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))

        @test findprev(≤(DateTime(2021, 1, 1, 0, 33)), tg, 10) == 3
        @test findprev(≤(DateTime(2021, 1, 1, 0, 30)), tg, 10) == 3
        @test findprev(≤(DateTime(2021, 1, 1, 0, 29)), tg, 10) == 2

        @test findprev(≤(DateTime(2021, 1, 1, 0, 33)), tg,  3) == 3
        @test findprev(≤(DateTime(2021, 1, 1, 0, 30)), tg,  3) == 3
        @test findprev(≤(DateTime(2021, 1, 1, 0, 29)), tg,  3) == 2

        @test findprev(≤(DateTime(2021, 1, 1, 0, 33)), tg,  2) == 2
        @test findprev(≤(DateTime(2021, 1, 1, 0, 30)), tg,  2) == 2
        @test findprev(≤(DateTime(2021, 1, 1, 0, 29)), tg,  2) == 2

        @test findprev(<(DateTime(2021, 1, 1, 0, 33)), tg, 10) == 3
        @test findprev(<(DateTime(2021, 1, 1, 0, 30)), tg, 10) == 2
        @test findprev(<(DateTime(2021, 1, 1, 0, 29)), tg, 10) == 2
    end
end


end  # @testset "TimeGrid"
