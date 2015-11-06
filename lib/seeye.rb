require "platform-api"
require "excon"
require "rendezvous"
require_relative "seeye/version"

module Seeye
  class << self
    def run(args)
      raise "Usage: seeye SOURCE_BLOB_URL" if args.empty?

      with_app_setup(args.first) do |app_setup|
        build_output_stream_url = wait_for_build_to_start(app_setup["id"])
        stream_build_output(build_output_stream_url)
        wait_for_build_to_finish(app_setup["id"])

        puts "Running tests..."
        run_test(app_setup["app"]["id"])
      end
    end

    def run_test(app_id)
      cmd = "rm -rf .bundle && bundle install && rake test" # make sure all development & test dependencies are installed
      dyno = heroku.dyno.create(app_id, command: cmd, attach: true)
      Rendezvous.start(
        :url => dyno["attach_url"]
      )
    end

    def stream_build_output(build_output_stream_url)
      streamer = lambda do |chunk, _, _|
        puts chunk
      end
      Excon.get(build_output_stream_url, response_block: streamer)
    end

    def wait_for_build_to_start(app_setup_id)
      info = heroku.app_setup.info(app_setup_id)
      while !info["build"]
        sleep 5
        info = heroku.app_setup.info(app_setup_id)
        print "."
      end

      info["build"]["output_stream_url"]
    end

    def wait_for_build_to_finish(app_setup_id)
      info = heroku.app_setup.info(app_setup_id)
      while info["status"] != "succeeded"
        sleep 5
        info = heroku.app_setup.info(app_setup_id)
        print "."
      end
      puts
    end

    def with_app_setup(source_blob)
      app_setup = heroku.app_setup.create(app_json(source_blob))
      app_id = app_setup["app"]["id"]
      puts "Creating one-off app..."
      begin
        yield app_setup
      ensure
        heroku.app.delete(app_id)
      end
    end

    def app_json(source_blob)
      {
        source_blob: {
          url: source_blob,
        },
        app: {
          loacked: true,
        },
        overrides: {
          env: {
            "RAILS_ENV": "development"
          }
        }
      }
    end

    def heroku
      @heroku ||= PlatformAPI.connect_oauth(ENV.fetch("HEROKU_API_TOKEN") { raise "Missing HEROKU_API_TOKEN" })
    end
  end
end
