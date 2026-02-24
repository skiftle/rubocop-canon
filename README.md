# rubocop-canon

Deterministic RuboCop cops that reduce Ruby code to canonical form. Given any input, there is exactly one correct output.

## Cops

| Cop | What it does |
|-----|-------------|
| `Canon/KeywordShorthand` | `foo(bar: bar)` becomes `foo(bar:)` |
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

`Canon/SortKeywords` and `Canon/SortMethodArguments` are disabled by default. They require a `Methods` list to function.

## License

MIT
