# EqualsByField

A package for doing customised comparison of objects, especially focussed on
fieldwise comparison of composite objects.

## Installation

```
using Pkg
pkg"add https://github.com/GHTaarn/EqualsByField.jl"
```

## Use

There are two exported symbols:
 - `equalsbyfield` which is a versatile comparison function
 - `≗` - a customisable binary operator version of `equalsbyfield`

### Example

```julia-repl
julia> using EqualsByField

julia> struct A
       a
       b
       end

julia> A(1,[2,3]) == A(1,[2,3])
false

julia> A(1,[2,3]) ≗ A(1,[2,3])
true

julia> A(1,[2,NaN]) ≗ A(1,[2,NaN])
false

julia> equalsbyfield(A(1,[2,NaN]), A(1,[2,NaN])) do x, y
       x == y || (all(typeof.([x,y]) .<: AbstractFloat) && all(isnan.([x,y])))
       end
true

julia> 
```

## Related packages

If one wishes to do fieldwise comparison of structs then it is often preferable
to use [StructEquality.jl](https://github.com/jolin-io/StructEquality.jl).
`EqualsByField.jl` is preferable when one wishes to do specialised comparisons
that do not easily translate to `==`, `isequal` or `isapprox`.

