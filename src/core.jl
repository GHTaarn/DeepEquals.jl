
export deepequals, ≗
VERSION >= v"1.11-alpha" && eval(Meta.parse("public opsettings, naneq"))

"""
    deepequals(equals, a, b; recursive=true, typeequality=(x,y)->typeof(x)==typeof(y))

Test for equality of `a` and `b` in a customisable way.
The return value is determined from the following sequence:

 1. Return `true` if `equals(a,b)`
 2. Return `false` if `!typeequality(a,b)`
 3. Return `false` if either `a` or `b` has no fields
 4. Return `false` if `a` and `b` have different fields
 5. Return `false` if applying `deepequals` on any field in `a` and `b` returns `false`
 6. If none of the above, return `true`

If `recursive==false`, `equals` instead of `deepequals` is applied in step 5

## Example

```julia
struct A
    a
    b
end

# The following line returns true even though A(1,[2,3]) != A(1,[2,3])
deepequals(==, A(1,[2,3]), A(1,[2,3]))

struct B
    b
    a
end

# The following expression also returns true due to the custom
# `equals` function and the type check in step 2 being switched off
deepequals(A(1,[2,3]), B([2,3], 1.5); typeequality=Returns(true)) do x, y
    if any(typeof.([x, y]) .<: AbstractFloat)
        abs(x-y) < 1
    else
        x == y
    end
end
```
"""
function deepequals(equals, a, b; recursive=true, typeequality=(x,y)->typeof(x)==typeof(y))
    equals(a, b) && return true
    typeequality(a, b) || return false
    fna = fieldnames(typeof(a))
    fnb = fieldnames(typeof(b))
    issetequal(fna, fnb) || return false
    isempty(fna) && return false # This assumes !equals(a,b) which should be the case for immutables and a decent equals function
    if recursive
        for fn in fna
            deepequals(equals, getfield(a, fn), getfield(b, fn); typeequality) || return false
        end
    else
        for fn in fna
            equals(getfield(a, fn), getfield(b, fn)) || return false
        end
    end
    return true
end

"""
    deepequals(equals, a::AbstractArray, b::AbstractArray; recursive=true, typeequality=(x,y)->typeof(x)==typeof(y))

Test for equality of `a` and `b` in a customisable way.
The return value is determined from the following sequence:

 1. Return `true` if `equals(a,b)`
 2. Return `false` if `!typeequality(a,b)`
 3. Return `false` if there is no `axes` or `iterate` method for either `a` or `b`
 4. Return `false` if `a` and `b` have different axes
 5. Return `false` if applying `deepequals` on any corresponding element in `a` and `b` returns `false`
 6. If none of the above, return `true`

If `recursive==false`, `equals` instead of `deepequals` is applied in step 5
"""
function deepequals(equals, a::AbstractArray, b::AbstractArray; recursive=true, typeequality=(x,y)->typeof(x)==typeof(y))
    equals(a, b) && return true
    typeequality(a, b) || return false
    if !all(hasmethod(iterate, (typeof(x),)) for x in [a,b]) || !all(hasmethod(axes, (typeof(x),)) for x in [a,b])
        @warn "Missing iterate or axes method"
        return false
    end
    axes(a) == axes(b) || return false
    if recursive
        return all(deepequals(equals, x, y; typeequality) for (x,y) in zip(a, b))
    else
        return all(equals(x, y) for (x,y) in zip(a, b))
    end
end

"""
    deepequals(a, b; recursive=true)

Equivalent to `deepequals(==, a, b; recursive)`
"""
deepequals(a, b; recursive=true) = deepequals(==, a, b; recursive)

"""
    naneq(a, b)

Return `true` if `a == b` or if both `a` and `b` are `missing`. Also, if
both `a` and `b` are `AbstractFloat` and `isnan` is `true` on both, then `true`
is also returned.
Return `false` in all other cases.
"""
naneq(a, b) = a == b
naneq(a::AbstractFloat, b::AbstractFloat) = a == b || all(isnan.((a,b)))
naneq(a::Missing, b::Missing) = true
naneq(a, b::Missing) = false
naneq(a::Missing, b) = false

"""
    DeepEquals.opsettings::Dict{Symbol,Any}

The settings for the [`≗`](@ref) operator. These are initially set to
`:equals=>DeepEquals.naneq`, `:recursive=>true` and `:typeequality=>(x,y)->typeof(x)==typeof(y)`
"""
const opsettings = Dict((:equals=>naneq, :recursive=>true, :typeequality=>(x,y)->typeof(x)==typeof(y)))

"""
    ≗(a, b)

A special equality operator with the following properties:

 1. For any deterministic function `f`, `f(x...) ≗ f(x...)` always returns `true`.
 2. `a ≗ b` must return `false` if `a` and `b` cannot have been produced by a deterministic function with the same input.

Shorthand for `deepequals(DeepEquals.opsettings[:equals], a, b; recursive=DeepEquals.opsettings[:recursive], typeequality=DeepEquals.opsettings[:typeequality])`
"""
≗(a, b) = deepequals(opsettings[:equals], a, b; recursive=opsettings[:recursive], typeequality=opsettings[:typeequality])

