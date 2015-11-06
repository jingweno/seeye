# Seeye

Seeye runs tests on Heroku. Currently only Rails tests are supported.
It sets up a "one-off app" using [app.json](https://devcenter.heroku.com/articles/app-json-schema) and runs tests with [one-off dyno](https://devcenter.heroku.com/articles/one-off-dynos).

## Usage

After cloning this repo:

```ruby
$ bundle install
$ HEROKU_API_TOKEN=xx ./bin/seeye https://github.com/jingweno/ruby-rails-sample/tarball/master/ # make sure it has app.json
```

## Demo

[![asciicast](https://asciinema.org/a/29432.png)](https://asciinema.org/a/29432)

## Other arts

* [seaeye](https://github.com/geemus/seaeye)
