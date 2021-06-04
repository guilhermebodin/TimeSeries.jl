using Base.Iterators
using Dates
using IntervalSets
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
    @testset "by index, finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @info "getindex(i, ::Int) :: $(typeof(tg))"

        @test tg[1]   == tg.o
        @test tg[2]   == DateTime(2021, 1, 1, 0, 15)
        @test tg[end] == tg.o + 9 * Minute(15)
        @test_throws BoundsError tg[0]
        @test_throws BoundsError tg[11]
        @test_throws BoundsError tg[-42]
    end

    @testset "by index, infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @info "getindex(i, ::Int) :: $(typeof(tg))"

        @test tg[1] == tg.o
        @test tg[2] == DateTime(2021, 1, 1, 0, 15)
        @test_throws BoundsError tg[0]
        @test_throws BoundsError tg[-42]
    end

    @testset "by time, finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @info "getindex(i, ::TimeType) :: $(typeof(tg))"

        @test tg[tg.o]    == 1
        @test tg[tg[2]]   == 2
        @test tg[tg[end]] == 10

        @test_throws KeyError tg[DateTime(2019, 1, 1)]
        @test_throws KeyError tg[DateTime(2022, 1, 1)]
    end

    @testset "by time, infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @info "getindex(i, ::TimeType) :: $(typeof(tg))"

        @test tg[tg.o]    == 1
        @test tg[tg[2]]   == 2
        @test tg[tg[42]]  == 42

        @test_throws KeyError tg[DateTime(2019, 1, 1)]
    end
end   # @testset "getindex"


@testset "find*" begin
    # TODO: test cases for benchmarking against tg and vg

    function test_findprev(tg::TimeGrid, vg)
        for f ∈ [≤, <, ≥, >, ==, isequal]
            @info "findprev :: $(typeof(tg)) :: f -> $f"

            @test findprev(f(DateTime(2021, 1, 1, 0, 33)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 33)), vg, 10)
            @test findprev(f(DateTime(2021, 1, 1, 0, 30)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 30)), vg, 10)
            @test findprev(f(DateTime(2021, 1, 1, 0, 29)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 0, 29)), vg, 10)
            @test findprev(f(DateTime(2021, 1, 1)),        tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1)),        vg, 10)
            @test findprev(f(DateTime(2021, 1, 1, 2, 15)), tg, 10) ==
                  findprev(f(DateTime(2021, 1, 1, 2, 15)), vg, 10)

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

            @test_throws BoundsError findprev(f(DateTime(2021, 1, 1, 0, 33)), tg, 0)
            @test_throws BoundsError findprev(f(DateTime(2021, 1, 1, 0, 33)), tg, -1)
            if Base.haslength(tg)
                @test_throws BoundsError findprev(f(DateTime(2021, 1, 1, 0, 33)), tg, 42)
            end
        end
    end

    @testset "findprev finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        vg = collect(tg)
        test_findprev(tg, vg)
    end

    @testset "findprev infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        vg = collect(Iterators.take(tg, 10))
        test_findprev(tg, vg)
    end

    function test_findnext(tg::TimeGrid, vg)
        for f ∈ [≤, <, ≥, >, ==, isequal]
            @info "findnext :: $(typeof(tg)) :: f -> $f"

            @test findnext(f(DateTime(2021, 1, 1, 0, 33)), tg,  1) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 33)), vg,  1)
            @test findnext(f(DateTime(2021, 1, 1, 0, 30)), tg,  1) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 30)), vg,  1)
            @test findnext(f(DateTime(2021, 1, 1, 0, 29)), tg,  1) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 29)), vg,  1)
            @test findnext(f(DateTime(2021, 1, 1)),        tg,  1) ==
                  findnext(f(DateTime(2021, 1, 1)),        vg,  1)
            @test findnext(f(DateTime(2021, 1, 1, 2, 15)), tg,  1) ==
                  findnext(f(DateTime(2021, 1, 1, 2, 15)), vg,  1)

            @test findnext(f(DateTime(2021, 1, 1, 0, 33)), tg,  3) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 33)), vg,  3)
            @test findnext(f(DateTime(2021, 1, 1, 0, 30)), tg,  3) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 30)), vg,  3)
            @test findnext(f(DateTime(2021, 1, 1, 0, 29)), tg,  3) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 29)), vg,  3)

            @test findnext(f(DateTime(2021, 1, 1, 0, 33)), tg,  2) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 33)), vg,  2)
            @test findnext(f(DateTime(2021, 1, 1, 0, 30)), tg,  2) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 30)), vg,  2)
            @test findnext(f(DateTime(2021, 1, 1, 0, 29)), tg,  2) ==
                  findnext(f(DateTime(2021, 1, 1, 0, 29)), vg,  2)

            @test findnext(f(Date(2019, 1, 1)), tg,  2) ==
                  findnext(f(Date(2019, 1, 1)), vg,  2)
            @test findnext(f(Date(2019, 1, 1)), tg,  2) ==
                  findnext(f(Date(2019, 1, 1)), vg,  2)
            @test findnext(f(Date(2019, 1, 1)), tg,  2) ==
                  findnext(f(Date(2019, 1, 1)), vg,  2)

            @test_throws BoundsError findnext(f(DateTime(2021, 1, 1, 0, 33)), tg, 0)
            @test_throws BoundsError findnext(f(DateTime(2021, 1, 1, 0, 33)), tg, -1)
            if Base.haslength(tg)
                @test_throws BoundsError findnext(f(DateTime(2021, 1, 1, 0, 33)), tg, 42)
            end
        end
    end

    @testset "findnext finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        vg = collect(tg)
        test_findnext(tg, vg)
    end

    @testset "findnext infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        vg = collect(Iterators.take(tg, 20))
        test_findnext(tg, vg)
    end

    function test_findfirst(tg::TimeGrid, vg)
        for f ∈ [≤, <, ≥, >, ==, isequal]
            @info "findfirst :: $(typeof(tg)) :: f -> $f"

            @test findfirst(f(DateTime(2021, 1, 1, 0, 33)), tg) ==
                  findfirst(f(DateTime(2021, 1, 1, 0, 33)), vg)
            @test findfirst(f(DateTime(2021, 1, 1, 0, 30)), tg) ==
                  findfirst(f(DateTime(2021, 1, 1, 0, 30)), vg)
            @test findfirst(f(DateTime(2021, 1, 1, 0, 29)), tg) ==
                  findfirst(f(DateTime(2021, 1, 1, 0, 29)), vg)
            @test findfirst(f(DateTime(2021, 1, 1)),        tg) ==
                  findfirst(f(DateTime(2021, 1, 1)),        vg)
            @test findfirst(f(DateTime(2021, 1, 1, 2, 15)), tg) ==
                  findfirst(f(DateTime(2021, 1, 1, 2, 15)), vg)
            @test findfirst(f(Date(2019, 1, 1)), tg) ==
                  findfirst(f(Date(2019, 1, 1)), vg)
        end
    end

    @testset "findfirst finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        vg = collect(tg)
        test_findfirst(tg, vg)
    end

    @testset "findfirst infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        vg = collect(Iterators.take(tg, 20))
        test_findfirst(tg, vg)
    end

    function test_findlast(tg::TimeGrid, vg)
        for f ∈ [≤, <, ≥, >, ==, isequal]
            @info "findlast :: $(typeof(tg)) :: f -> $f"

            if !Base.haslength(tg) && f ∈ [≥, >]
                @test_throws DomainError findlast(f(DateTime(2021, 1, 1)), tg)
                continue
            end

            @test findlast(f(DateTime(2021, 1, 1, 0, 33)), tg) ==
                  findlast(f(DateTime(2021, 1, 1, 0, 33)), vg)
            @test findlast(f(DateTime(2021, 1, 1, 0, 30)), tg) ==
                  findlast(f(DateTime(2021, 1, 1, 0, 30)), vg)
            @test findlast(f(DateTime(2021, 1, 1, 0, 29)), tg) ==
                  findlast(f(DateTime(2021, 1, 1, 0, 29)), vg)
            @test findlast(f(DateTime(2021, 1, 1)),        tg) ==
                  findlast(f(DateTime(2021, 1, 1)),        vg)
            @test findlast(f(DateTime(2021, 1, 1, 2, 15)), tg) ==
                  findlast(f(DateTime(2021, 1, 1, 2, 15)), vg)
            @test findlast(f(Date(2019, 1, 1)), tg) ==
                  findlast(f(Date(2019, 1, 1)), vg)
        end
    end

    @testset "findlast finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        vg = collect(tg)
        test_findlast(tg, vg)
    end

    @testset "findlast infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        vg = collect(Iterators.take(tg, 20))
        test_findlast(tg, vg)
    end
end  # @testset "find*"


@testset "count" begin
    function test_count(tg::TimeGrid)
        @info "count :: $(typeof(tg))"

        @test count(DateTime(2020, 1, 1)..DateTime(2020, 2, 1), tg) == 0
        @test count(DateTime(2020, 1, 1)..DateTime(2021, 1, 1), tg) == 1
        @test count(DateTime(2020, 1, 1)..DateTime(2021, 1, 1, 2, 15), tg) == 10
    end

    @testset "finit" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        test_count(tg)
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        test_count(tg)
    end
end  # @testset "count"


@testset "reduce" begin
    @testset "finit" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @info "reduce :: $(typeof(tg))"

        @test reduce(max, tg) == tg[end]
        @test reduce(max, tg, init = DateTime(2077, 1, 1)) == DateTime(2077, 1, 1)
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @info "reduce :: $(typeof(tg))"

        @test_throws BoundsError reduce(max, tg)
    end
end


@testset "foldl" begin
    @testset "finit" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @info "foldl :: $(typeof(tg))"

        @test foldl(max, tg) == tg[end]
        @test foldl(max, tg, init = DateTime(2077, 1, 1)) == DateTime(2077, 1, 1)
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @info "foldl :: $(typeof(tg))"

        @test_throws BoundsError foldl(max, tg)
    end
end


@testset "foldr" begin
    @testset "finit" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @info "foldr :: $(typeof(tg))"

        @test foldr(max, tg) == tg[end]
        @test foldr(max, tg, init = DateTime(2077, 1, 1)) == DateTime(2077, 1, 1)
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @info "foldr :: $(typeof(tg))"

        @test_throws MethodError foldr(max, tg)
    end
end


@testset "view" begin
    @testset "finite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15), 10)
        @info "view :: $(typeof(tg))"

        @test view(tg, 2:9)[1]   == DateTime(2021, 1, 1, 0, 15)
        @test view(tg, 2:2:10).p == Minute(30)
    end

    @testset "infinite" begin
        tg = TimeGrid(DateTime(2021, 1, 1), Minute(15))
        @info "view :: $(typeof(tg))"

        @test view(tg, 2:9)[1]    == DateTime(2021, 1, 1, 0, 15)
        @test view(tg, 2:9)[end]  == DateTime(2021, 1, 1, 2, 0)
        @test view(tg, 2:2:10).p  == Minute(30)
    end
end


end  # @testset "TimeGrid"
