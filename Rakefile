require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'json'
require 'yaml'
require 'service_client'

# Validates that the specified file exists, raising an error if it does not.
# Then reads the file into a string which is returned
#
# @param file [String] the path to the file which should be returned as a string
#
# @return [String] the content of the supplied file
def file_to_str_and_validate(file)
  cat_str = File.open(File.expand_path(file), 'r') { |f| f.read }
end

# Returns a Service::Client which is already configured and authenticated using
# the information found in ~/.right_api_client/login.yml
#
# @return [Service::Client] an initialized Service Client
def get_client
  options = YAML.load_file(
    File.expand_path("#{ENV['HOME']}/.right_api_client/login.yml")
  )
  service_client = Service::Client.new(options)
end

def compile_template(client, template_source)
  begin
    client.compile_template({'source' => template_source})
    puts "Template compiled successfully"
  rescue RightApi::ApiError => e
    puts "Failed to compile template"
    response = service_client.last_request[:response]
    errors = JSON.parse(response.body)
    puts JSON.pretty_generate(errors).gsub('\n',"\n")
  end
end

def preprocess_template(file)
  parent_template = file_to_str_and_validate(file)
  parent_template.scan(/#include:(.*)$/).each do |include|
    include_filepath = File.expand_path(include.first, File.dirname(file))
    include_contents = <<EOF
###############################################################################
# BEGIN Include from #{include.first}
###############################################################################
EOF

    include_contents += file_to_str_and_validate(include_filepath)

    include_contents += <<EOF
###############################################################################
# END Include from #{include.first}
###############################################################################
EOF

    parent_template.sub!("#include:#{include.first}",include_contents)
  end
  parent_template
end

desc "Compile a template to discover any syntax errors"
task :compile, [:filepath] do |t,args|
  cat_str = preprocess_template(args[:filepath])

  service_client = get_client()
  compile_template(service_client, cat_str)
end

desc "Preprocess a template, replacing include:/path/to/file statements with file contents, and produce an output file.  Default output filepath is \"processed-\"+:input_filepath"
task :preprocess, [:input_filepath,:output_filepath] do |t,args|
  input_filedir = File.dirname(File.expand_path(args[:input_filepath]))
  input_filename = File.basename(args[:input_filepath])
  args.with_defaults(:output_filepath => File.join(input_filedir, "processed-#{input_filename}"))
  output_filepath = File.expand_path(args[:output_filepath])
  processed_template = preprocess_template(args[:input_filepath])
  File.open(File.expand_path(output_filepath), 'w') {|f| f.write(processed_template)}

  puts "Created a processed file at #{output_filepath}"
end
