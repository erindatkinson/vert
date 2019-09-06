# Vert: A simple YAML/JSON converter

![tree in a broken globe](assets/environmental-protection-326923_1920.jpg)

## Background

I had a simple dream, to have a json/yaml converter that I could run as either a CLI tool, a webserver, or an api server. The catch? I wanted the core engine(like 2 lines of code this time) to be the same no matter what.

Thus (con) vert was born.

## Installation

### Requisites

* Python 3.6+
* make (optional)

### Makefile

Running `make install` will create a directory `~/.local/bin/python` if it doesn't already exist.
Adding `~/.local/bin/python` to your $PATH variable will allow you to run `vert` from anywhere.

## Limitations

This is basically a little side project to explicitly show myself that my idea wasn't out of the realm of possibility or reason, there's a LOT of edge cases and addenda that aren't covered. Under no circumstances should you run this as a production thing.

## Future thoughts

I plan on adding a docker manifests for this as well for both the webserver endpoint and the api endpoint.

## License

This project is licensed under the Apache 2.0 License [docs/LICENSE](docs/LICENSE).

## Code of Conduct

This project operates under the Contributor Covenant [docs/code-of-conduct.md](docs/code-of-conduct.md)
