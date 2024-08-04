# Metar

## TODO
* Add parsing tokens that represent good weather conditions (like *CAVOK*)
* Document the code. Include domain knowledge about METAR.
* Refactor function naming.
* Add support for different METAR types (only US type is currently supported).
* Add unit tests.
* Add flight category determination (like *VFR*).
* Split code into several modules?
* Write description in the README file.
* **Add parsing other tokens**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `metar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:metar, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/metar>.
