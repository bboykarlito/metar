# Metar

## TODO
* Currently, only prevailing visibility is parsed. Several Visibility values for different directions should be added.
* Add flight category determination (like *VFR*).
* Add unit tests.
* **Add parsing other tokens**

## Installation

The package can be installed by adding `metar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:metar, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/metar>.
