# Compilers

This repo contains a collection of parsers, tokenizers, compilers, interpreters and other stuff around them
which I wrote in Elixir.

Currently, it contains only an optimized `Brainfuck` compiler to `C`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `compilers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:compilers, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/compilers>.
