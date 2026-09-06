# rubocop-canon

Deterministic RuboCop cops that reduce Ruby code to canonical form. Given any input, there is exactly one correct output.

## Cops

| Cop | What it does |
|-----|-------------|
| `Canon/BlockPhases` | A block body ends in one unbroken run of calls, opened by one blank line |
| `Canon/DeclarationGroups` | One blank line between declaration groups, none inside a group |
| `Canon/KeywordShorthand` | `foo(bar: bar)` becomes `foo(bar:)` |
| `Canon/MethodBodyBlankLines` | One blank line around a method body's standalone calls, none anywhere else |
| `Canon/SortHash` | `{b: 1, a: 2}` becomes `{a: 2, b: 1}` |
| `Canon/SortKeywords` | `method(z: 1, a: 2)` becomes `method(a: 2, z: 1)` |
| `Canon/SortMethodArguments` | `attr_reader :z, :a` becomes `attr_reader :a, :z` |
| `Canon/SortMethodDefinition` | `def foo(z:, a:)` becomes `def foo(a:, z:)` |

## Installation

Add to your Gemfile:

```ruby
gem 'rubocop-canon', require: false
```

Add to your `.rubocop.yml`:

```yaml
plugins:
  - rubocop-canon
```

## Configuration

The blank-line cops are driven by name lists:

```yaml
Canon/BlockPhases:
  Blocks:                   # only check blocks of these methods (required)
    - it
  TrailingMethods:          # calls that make up the trailing phase (required)
    - expect
  MaxPhases: 3              # phases allowed before the trailing one

Canon/DeclarationGroups:
  GroupedMethods:           # method names that form one group
    - [belongs_to, has_many, has_one]
    - [validate, validates]

Canon/MethodBodyBlankLines:
  SeparatedMethods:         # calls that take a blank line beside them
    - expose
    - mail
    - errors.add            # dotted: matches a receiver and method together
```

`Canon/BlockPhases` does nothing without both lists. `Canon/DeclarationGroups` treats every
method name as its own group until `GroupedMethods` merges them. `Canon/MethodBodyBlankLines`
only removes blank lines until `SeparatedMethods` says where they belong.

`Canon/SortHash` and the three sort cops accept:

```yaml
Canon/SortHash:
  ShorthandsFirst: true     # shorthand pairs sort before expanded
  ExcludeMethods:           # skip hashes inside these methods
    - enum

Canon/SortKeywords:
  ShorthandsFirst: true
  Methods:                  # only check these methods (required)
    - attribute
    - belongs_to

Canon/SortMethodArguments:
  Methods:                  # only check these methods (required)
    - attr_reader
    - delegate
```

Every cop is disabled by default. Enable the ones you want in your `.rubocop.yml`.

## License

MIT
