# KinoUserPresence

`KinoUserPresence` is an Elixir module that provides user presence tracking functionality for Livebook applications. It
monitors user connections, tracks activity through heartbeats, and executes callbacks when users join or leave.

## Features

- Real-time user presence tracking
- Customizable join and leave callbacks
- Heartbeat mechanism to detect inactive users

## Installation

Add `kino_user_presence` to your list of dependencies in `mix.exs`:

```elixir
Mix.install(
  [
    {:kino_user_presence, "~> 0.1.0"}
  ]
  )
```

## Usage

To use `KinoUserPresence` in your Livebook application:

Import the module:

```elixir
KinoUserPresence.listen(
    fn origin -> IO.puts("#{origin} joined") end,
    fn origin -> IO.puts("#{origin} left") end
)
```

## Configuration

The module uses the following default configuration:

- Heartbeat interval: 100 milliseconds
- Grace period: 3 heartbeat intervals

You can modify these values by changing the module attributes in the source code.

## Development

To set up the project for development:

1. Clone the repository
2. Run mix deps.get to fetch dependencies
3. Run mix test to execute the test suite

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License - see the LICENSE file for details.