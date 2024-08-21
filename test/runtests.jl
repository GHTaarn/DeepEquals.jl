using Test
using DeepEquals

@testset "≗" begin
    struct A
        a
        b
    end

    @test A(A(missing,[2,NaN]),(-0.0,"A")) ≗ A(A(missing,[2,NaN]),(0.0,"A"))
    @test (A(A(missing,[2,NaN]),(-0.0,"A")) ≗ A(A(missing,[NaN,NaN]),(0.0,"A"))) == false
end

