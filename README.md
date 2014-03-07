# Stochastic library for the D programming Language

## Goal

This library implements various functions useful for stochastic simulations. Currently the project contains a simple implementation of the Gillespie algorithm. It also add  support for drawing random values from normal and exponential distributions.

## Installation

Easiest is to require the library as a dependency in your dub.conf 

```JSON
{
  ...
  "dependencies": {
    "stochastic": "~master"
  }
}
```

## Examples

See the example directory for some examples

Examples can be compiled and run with

    dub --config=<example_name>


## Documentation

Run the following to generate API documentation

    dub docs

### Gillespie

The Gillespie algorithm execute events in random order. Events with a larger rate will happen more often than events with a low rate. The algorithm is currently implemented using EventList, which will return the time till the next event and the next event.

## License

The library is distributed under the GPL-v3 license. See the file COPYING for more details.
