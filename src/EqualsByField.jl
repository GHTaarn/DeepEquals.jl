module EqualsByField

export equalsbyfield, ≗

"""
    equalsbyfield(equals, a, b; recursive=true, typeequality=(x,y)->typeof(x)==typeof(y))

Test for equality of `a` and `b` in a customisable way.
The return value is determined from the following sequence:

 1. Return `true` if `equals(a,b)`
 2. Return `false` if `!typeequality(a,b)`
 3. Return `false` if `a` and `b` have different fields
 4. If `a` and `b` have no fields then attempt to compare as iterables or return `false`
 5. Return `false` if applying `equalsbyfield` on any field in `a` and `b` returns `false`
 6. If none of the above, return `true`

If `recursive==false`, `equals` instead of `equalsbyfield` is applied in step 5

Step 4 works on built in `Array` types, but it is best to check the source code
if other iterables are used.

## Example

```julia
struct A
    a
    b
end

# The following line returns true even though A(1,[2,3]) != A(1,[2,3])
equalsbyfield(==, A(1,[2,3]), A(1,[2,3]))

struct B
    b
    a
end

# The following expression also returns true due to the custom
# `equals` function and the type check in step 2 being switched off
equalsbyfield(A(1,[2,3]), B([2,3], 1.5); typeequality=Returns(true)) do x, y
    if any(typeof.([x, y]) .<: AbstractFloat)
        abs(x-y) < 1
    else
        x == y
    end
end
```
"""
function equalsbyfield(equals, a, b; recursive=true, typeequality=(x,y)->typeof(x)==typeof(y))
    equals(a, b) && return true
    typeequality(a, b) || return false
    fna = fieldnames(typeof(a))
    fnb = fieldnames(typeof(b))
    issetequal(fna, fnb) || return false
    if isempty(fna)
        all(hasmethod(iterate, (typeof(x),)) for x in [a,b]) || return false
        all(hasmethod(axes, (typeof(x),)) for x in [a,b]) || return false
        axes(a) == axes(b) || return false
        if recursive
            return all(equalsbyfield(equals, x, y; typeequality) for (x,y) in zip(a,b))
        else
            return all(equals(x, y) for (x,y) in zip(a,b))
        end
    end
    if recursive
        for fn in fna
            equalsbyfield(equals, getfield(a, fn), getfield(b, fn); typeequality) || return false
        end
    else
        for fn in fna
            equals(getfield(a, fn), getfield(b, fn)) || return false
        end
    end
    return true
end

"""
    equalsbyfield(a, b; recursive=true)

Equivalent to `equalsbyfield(==, a, b; recursive)`
"""
equalsbyfield(a, b; recursive=true) = equalsbyfield(==, a, b; recursive)

const opsettings = Dict((:equals=>(==), :recursive=>true, :typeequality=>(x,y)->typeof(x)==typeof(y)))

"""
    ≗(a, b)

Shorthand for `equalsbyfield(EqualsByField.opsettings[:equals], a, b; recursive=EqualsByField.opsettings[:recursive], typeequality=EqualsByField.opsettings[:typeequality])`
"""
≗(a, b) = equalsbyfield(opsettings[:equals], a, b; recursive=opsettings[:recursive], typeequality=opsettings[:typeequality])

end # module EqualsByField
