require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'json'
require 'yaml'
require 'service_client'

task :syntax_check, [:filepath] do |t,args|
  unless File.exist?(File.expand_path(args[:filepath]))
    raise "Unable to find file #{args[:filepath]}"
  end
  cat_str = File.open(args[:filepath], 'r') { |f| f.read }

  options = YAML.load_file(
    File.expand_path("#{ENV['HOME']}/.right_api_client/login.yml")
  )
  service_client = Service::Client.new(options)
  #service_client.log(STDOUT)

  begin
    service_client.compile_template({'source' => cat_str})
    puts "Template compiled successfully"
  rescue RightApi::ApiError => e
    puts "Failed to compile template"
    response = service_client.last_request[:response]
    errors = JSON.parse(response.body)
    puts JSON.pretty_generate(errors).gsub('\n',"\n")
  end
end
