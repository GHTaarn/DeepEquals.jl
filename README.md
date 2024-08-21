# DeepEquals

A package for doing customised comparison of objects, especially focussed on
itemwise comparison of composite objects.

## Installation

```
using Pkg
pkg"add https://github.com/GHTaarn/DeepEquals.jl"
```

## Use

There are two exported symbols:
 - `deepequals` which is a versatile comparison function
 - `≗` - a binary operator version of `deepequals` that handles `NaN` and `missing` values in a similar way to `Base.isequal`

The `≗` operator is specialised to handle the situation where one has
calculated a result and wants to check if it is equal to a benchmark result
that has been calculated in a slightly different way.
By default, the `≗` operator will handle simple cases correctly and can be
tweaked if necessary.

### Example

```julia-repl
julia> using DeepEquals

julia> struct A
       a
       b
       end

julia> A(1,[2,3]) == A(1,[2,3])
false

julia> A(1,[2,3]) ≗ A(1,[2,3])
true

julia> A(A(missing,[2,NaN]),-0.0) ≗ A(A(missing,[2,NaN]),0.0)
true

julia> deepequals(A(1,[2,NaN]), A(1,[2,NaN])) do x, y
       x == y || (all(typeof.([x,y]) .<: AbstractFloat) && all(isnan.([x,y])))
       end
true

julia> 
```

## Related packages

[StructEquality.jl](https://github.com/jolin-io/StructEquality.jl) is a good
package for generating `==`, `isequal` and `isapprox` methods for structs.
`DeepEquals.jl` is preferable when one wishes to do specialised comparisons
that do not easily translate to `==`, `isequal` or `isapprox`.

