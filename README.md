# Stochastic library for the D programming Language

## Goal

This library implements various functions useful for stochastic simulations. Currently the project contains a simple implementation of the Gillespie algorithm. It also add  support for drawing random values from normal and exponential distributions. 

## Installation

Easiest is to require the library as a dependency in your dub.conf 

```JSON
{
	...
  "dependencies": {
    "test_repos": ">=0.0.7"
  }
}
```

## Examples

See the example directory for some examples

## Documentation

Run the following to generate documentation

    dub docs


## License

The library is distributed under the GPL-v3 license. See the file COPYING for more details.
