# envpp

Replaces all environment variable references in a text file with their corresponding
values in currently set environment variables.

```sh
$ echo 'foo: $(bar)' >> config.yaml
$ bar="bar" cat config.yaml | envpp
foo: bar
```

The sole reason this exists is to allow me to easily work with configuration
files I have defined in Azure pipelines. For example, I may have a values
file for some helm chart whose installation is automated through Azure
pipelines. In Azure pipelines I have the following values file defined:

```yaml
global:
  username: "$(USERNAME)"
  password: "$(PASSWORD)"
```

`$(USERNAME)` and `$(PASSWORD)` are custom variables I have defined, so
azure pipelines conviniently replaces them for me in the file. Now,
sometimes when the installation is failing in Azure I do try to test
out things on my computer locally. Before I had this, I had to copy
the file then manually edit it to replace the variables and then use
it (helm values files can get hairy). With this tool, that's changed.
Right now, I copy the file then save it locally. I leave the variables
in the original file as is (if need be I add some more) and then
generate copies using this tool.

```sh
$ source .env
$ envpp < values.yaml.source > values.yaml
```
When I am done, I copy the source file with any modifications I have
made back to azure devops.

## Installation

Grab an x86-64 binary from the releases page or clone this project
and build it yourself.

```sh
crystal build --release src/envpp --release src/envpp
```

## Usage

```sh
$ envpp < source-file > output-file
```

## Development

Make your changes then run tests...

```sh
$ crystal spec
```

## Contributing

1. Fork it (<https://github.com/your-github-user/envpp/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Walter Kaunda](https://github.com/kwalter94) - creator and maintainer
