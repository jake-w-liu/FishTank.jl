using FishTank
using Test

@testset "Creation Functions" begin
    @testset "_create_fish" begin
        pos = [0.5, 0.5, 0.5]
        fish = FishTank._create_fish(pos, "red")
        @test fish isa FishTank.Fish
        @test fish.pos == pos
        @test fish.dir == [1.0, 0.0, 0.0]
        @test fish.body.color == "red"
        @test fish.tail.color == "red"
    end

    @testset "_create_food" begin
        food = FishTank._create_food(10)
        @test food isa FishTank.Food
        @test food.num == 10
        @test length(food.pts.x) == 10
        @test length(food.zd) == 10
    end

    @testset "_create_weed" begin
        weed = FishTank._create_weed()
        @test weed isa FishTank.Weed
        @test length(weed.pos) > 0
    end
end
