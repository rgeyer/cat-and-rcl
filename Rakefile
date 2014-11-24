require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'json'
require 'yaml'
require 'logger'
require 'formatador'
require 'rest-client'


################################################################################
# BEGIN: Helpers
#
#
################################################################################

# Validates that the specified file exists, raising an error if it does not.
# Then reads the file into a string which is returned
#
# @param file [String] the path to the file which should be returned as a string
#
# @return [String] the content of the supplied file
def file_to_str_and_validate(file)
  cat_str = File.open(File.expand_path(file), 'r') { |f| f.read }
end

# Gets options from ~/.right_api_client/login.yml
#
# @return [Hash] The options in ~/.right_api_client/login.yml converted to a hash
def get_options
  options = YAML.load_file(
    File.expand_path("#{ENV['HOME']}/.right_api_client/login.yml")
  )
end

def get_list_of_includes(file)
  dedupe_include_list = {}
  contents = file_to_str_and_validate(file)
  contents.scan(/#include:(.*)$/).each do |include|
    include_filepath = File.expand_path(include.first, File.dirname(file))
    dedupe_include_list.merge!({include_filepath => include.first})
    # This merges only the new keys by doing a diff
    child_includes_hash = get_list_of_includes(include_filepath)
    new_keys = child_includes_hash.keys() - dedupe_include_list.keys()
    merge_these = child_includes_hash.select {|k,v| new_keys.include?(k) }
    dedupe_include_list.merge!(merge_these)
  end
  dedupe_include_list
end

def preprocess_template(file)
  parent_template = file_to_str_and_validate(file)
  dedup_include_list = get_list_of_includes(file)

  dedup_include_list.each do |key,val|
    include_filepath = key
    include_contents = <<EOF
###############################################################################
# BEGIN Include from #{val}
###############################################################################
EOF

    include_contents += file_to_str_and_validate(key)

    include_contents += <<EOF
###############################################################################
# END Include from #{val}
###############################################################################
EOF

    parent_template.sub!("#include:#{val}",include_contents)
  end
  # Clear all include lines from templates which were included from other templates
  parent_template.gsub!(/#include:(.*)$/,"")
  parent_template
end

def template_create(template_filepath,auth)
  options = get_options()
  create_req = RestClient::Request.new(
    :method => :post,
    :url => "#{options[:selfservice_url]}/api/designer/collections/#{options[:account_id]}/templates",
    :payload => {
      :multipart => true,
      :source => File.new(template_filepath, "rb")
    },
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  create_req.execute
end

def template_update(template_id,template_filepath,auth)
  options = get_options()
  update_req = RestClient::Request.new(
    :method => :put,
    :url => "#{options[:selfservice_url]}/api/designer/collections/#{options[:account_id]}/templates/#{template_id}",
    :payload => {
      :multipart => true,
      :source => File.new(template_filepath, "rb")
    },
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  update_req.execute
end

def template_publish(template_filepath,auth)
  options = get_options()
  template = template_upsert(template_filepath,auth)
  template_id = template.split("/").last

  pub_req = RestClient::Request.new(
    :method => :post,
    :url => "#{options[:selfservice_url]}/api/designer/collections/#{options[:account_id]}/templates/actions/publish",
    :payload => URI.encode_www_form(
      :id => template_id
    ),
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  begin
    response = pub_req.execute
    application_href = response.headers[:location]
  rescue RestClient::ExceptionWithResponse => e
    puts "Failed to publish template"
    errors = JSON.parse(e.http_body)
    puts JSON.pretty_generate(errors).gsub('\n',"\n")
  end
  application_href
end

def template_republish(template_filepath,auth)
  application_href = ""
  options = get_options()
  template_id = template_upsert(template_filepath,auth).split("/").last
  template = file_to_str_and_validate(template_filepath)
  matches = template.match(/^name\s*"(?<name>.*)"/)
  name = matches["name"]

  applications = get_applications(auth)
  existing_applications = applications.select{|application| application["name"] == name }

  begin
    if existing_applications.length != 0
      application_href = existing_applications.first()["href"]
      pub_req = RestClient::Request.new(
        :method => :post,
        :url => "#{options[:selfservice_url]}/api/designer/collections/#{options[:account_id]}/templates/actions/publish",
        :payload => URI.encode_www_form(
          :id => template_id,
          :overridden_application_href => application_href
        ),
        :cookies => auth["cookie"],
        :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
      )
      pub_req_resp = pub_req.execute
    else
      response = template_publish(tmpfile.path,auth)
      application_href = response.headers[:location]
    end
  rescue RestClient::ExceptionWithResponse => e
    puts "Failed to republish template"
    errors = JSON.parse(e.http_body)
    puts JSON.pretty_generate(errors).gsub('\n',"\n")
  end
  application_href
end

def template_upsert(template_filepath,auth)
  template_href = ""
  options = get_options()
  template = preprocess_template(template_filepath)
  matches = template.match(/^name\s*"(?<name>.*)"/)
  tmp_file = matches["name"].gsub("/","-").gsub(" ","-")
  name = matches["name"]

  templates = get_templates(auth)
  existing_templates = templates.select{|template| template["name"] == name }

  tmpfile = Tempfile.new([tmp_file,".cat.rb"])
  begin
    tmpfile.write(template)
    tmpfile.close()
    if existing_templates.length != 0
      template_id = existing_templates.first()["id"]
      response = template_update(template_id,tmpfile.path,auth)
      template_href = "/api/designer/collections/#{options[:account_id]}/templates/#{template_id}"
    else
      response = template_create(tmpfile.path,auth)
      template_href = response.headers[:location]
    end
  rescue RestClient::ExceptionWithResponse => e
    puts "Failed to compile template"
    errors = JSON.parse(e.http_body)
    puts JSON.pretty_generate(errors).gsub('\n',"\n")
  ensure
    tmpfile.close!()
  end
  template_href
end

def execution_id_from_href(execution_href)
  execution_href.match(/\/api\/manager\/projects\/[0-9]+\/executions\/(?<id>.*)/)["id"]
end

################################################################################
# END: Helpers
#
#
################################################################################

################################################################################
# START: Test Classes
#
#
################################################################################

class BaseTest
  attr_accessor :status

  def initialize(filepath,auth)
    @errors = []
    @status = "initialized"
    @test_config = {}
    @auth = auth
    @filepath = filepath
    content = file_to_str_and_validate(@filepath)
    content.scan(/^(#test_?[operation]*:.*=.*)/) do |tag|
      key_value = tag.first.to_s.match(/test_?(?<sub>operation)?:(?<key>.*)=(?<val>.*)$/)
      if key_value.names.include?("sub") && key_value["sub"]
        @test_config[key_value["sub"]] = {} unless @test_config.has_key?(key_value["sub"])
        @test_config[key_value["sub"]][key_value["key"]] = key_value["val"]
      else
        @test_config[key_value["key"]] = key_value["val"]
      end
    end
  end

  def pump()
    if @test_config.keys().include?("compile_only") & @test_config["compile_only"]
      compile_only()
    else
      execution()
    end
  end

  def finished?()
    ["finished","failed"].include?(@status)
  end

  def errors()
    formatador = Formatador.new
    formatador.display_line("[red]#{File.basename(@filepath)}[/]")
    formatador.indent {
      @errors.each do |error|
        formatador.display_line("[red]#{error}[/]")
      end
    }
  end

  protected
  def handle_ss_error(e)
    error_lines = "#{e.to_s}\n"
    if e.response
      if e.response.headers[:content_type] == "application/json"
        error_lines += JSON.pretty_generate(JSON.parse(e.http_body)).gsub('\n',"\n")
      else
        error_lines += e.http_body
      end
    end
    error_lines
  end

  def compile_only()
    if @status == "initialized"
      formatador = Formatador.new
      formatador.display_line(File.basename(@filepath))
      template = preprocess_template(@filepath)
      success = false
      begin
        compile_template(@auth, template)
        success = true
      rescue RestClient::ExceptionWithResponse => e
        success = false
      end

      if @test_config.keys().include?("expected_state")
        expected_bool = @test_config["expected_state"] == "running"
        success = (success == expected_bool)
      end

      display_line = success ? "Compile: [_green_][black]SUCCESS[/]" : "Compile: [_red_][black]FAILURE[/]"
      if @test_config.keys().include?("desired_state")
        desired_bool = @test_config["desired_state"] == "running"
        if success != desired_bool
          display_line = "Compile: [_yellow_][black]EXPECTED FAILURE[/]"
        else
          display_line = "Compile: [_blue_][black]FIXED![/]"
        end
      end
      formatador.indent {
        formatador.display_line(display_line)
      }
      @status = "finished"
    end
  end

  def execution()
    case @status
    when "initialized"
      begin
        template = preprocess_template(@filepath)
        response = execution_create(template, @auth)
        @execution_href = response.headers[:location]
        @status = "executing"
      rescue RestClient::ExceptionWithResponse => e
        if @test_config.has_key?("desired_state")
          # Wierd corner case, demonstrated by
          # tests/system/output-map-must-assign-from-var.cat.rb where compile
          # succeeds, but the execution fails immediately.  Probably deserves
          # a unique case.
          @execution_status = "failed"
          @status = "print result"
        else
          @errors << "Failed to create execution"
          @errors << handle_ss_error(e)
          @status = "report failure"
        end
      end
    when "executing"
      begin
        execution = execution_get_by_href(@execution_href,@auth)
        if ["failed","running"].include?(execution["status"])
          @execution_status = execution["status"]
          if @test_config.has_key?("operation")
            @status = "start operations"
          else
            @status = "print result"
          end
        end
      rescue RestClient::ExceptionWithResponse => e
        @errors << "Failed to get execution - #{@execution_href}"
        @errors << handle_ss_error(e)
        @status = "report failure"
      end
    when "print result"
      formatador = Formatador.new
      formatador.display_line(File.basename(@filepath))
      if @test_config.keys().include?("operation") && @operations
        @operations.each do |operation_name,operation|
          formatador.indent {
            if operation["desired_result"] == operation["result"]
              formatador.display_line("#{operation_name}: [_green_][black]#{operation["result"].upcase}[/]")
            else
              formatador.display_line("#{operation_name}: [_red_][black]#{operation["result"].upcase}[/]")
            end
          }
        end
      else
        display_line = "Execute: [_green_][black]#{@execution_status.upcase}[/]"
        if @test_config.keys().include?("desired_state")
          if @execution_status != @test_config["desired_state"]
            display_line = "Execute: [_yellow_][black]EXPECTED #{@execution_status.upcase}[/]"
          else
            display_line = "Execute: [_blue_][black]FIXED! #{@execution_status.upcase}[/]"
          end
        elsif @test_config.keys().include?("expected_state")
          if @execution_status != @test_config["expected_state"]
            display_line = "Execute: [_red_][black]#{@execution_status.upcase}[/]"
          end
        elsif @execution_status == "failed"
          display_line = "Execute: [_red_][black]#{@execution_status.upcase}[/]"
        end
        formatador.indent {
          formatador.display_line(display_line)
        }
      end
      @status = "terminate"
    when "start operations"
      @operations = {}
      @test_config["operation"].each do |operation|
        op_hash = {"desired_result" => operation.last}
        begin
          response = operation_create(@execution_href, operation.first, @auth)
          op_hash["operation_href"] = response.headers[:location]
        rescue RestClient::ExceptionWithResponse => e
          @errors << "Failed to start operation #{operation.first} - #{@execution_href}"
          @errors << handle_ss_error(e)
          op_hash["result"] = "failed"
        end
        @operations[operation.first] = op_hash
      end
      @status = "wait for operations"
    when "wait for operations"
      if @operations
        @operations.each do |operation_name,operation|
          next if operation.has_key?("result")
          op_response = operation_get_by_href(operation["operation_href"], @auth)
          if op_response["timestamps"]["finished_at"]
            @operations[operation_name]["result"] = op_response["status"]["summary"]
          end
        end

        finished_ops = @operations.select {|k,v| v.has_key?("result") }
        if finished_ops.length == @operations.length
          @status = "print result"
        end
      else
        @status = "print result"
      end
    when "terminate"
      if @execution_href
        begin
          operation_response = operation_create(@execution_href,"terminate",@auth)
          @terminate_op_href = operation_response.headers[:location]
          @status = "terminating"
        rescue RestClient::ExceptionWithResponse => e
          @errors << "Failed to create terminate operation - #{@execution_href}"
          @errors << handle_ss_error(e)
          @status = "report failure"
        end
      else
        @status = "finished"
      end
    when "terminating"
      begin
        operation = operation_get_by_href(@terminate_op_href, @auth)
        if operation["status"]["summary"] == "completed"
          @status = "delete"
        end
      rescue RestClient::ExceptionWithResponse => e
        @errors << "Failed to get terminate operation status - #{@terminate_op_href}"
        @errors << handle_ss_error(e)
        @status = "report failure"
      end
    when "delete"
      begin
        execution_delete_by_href(@execution_href, @auth)
        @status = "finished"
      rescue RestClient::ExceptionWithResponse => e
        @errors << "Failed to delete execution - #{@execution_href}"
        @errors << handle_ss_error(e)
        @status = "report failure"
      end
    when "finished"
      # Do nothing
    when "report failure"
      formatador = Formatador.new
      formatador.display_line("[red]#{File.basename(@filepath)}[/]")
      formatador.indent {
        formatador.display_line("[red]Error: See details below[/]")
      }
      @status = "failed"
    when "failed"
      # Do nothing
    else
      @errors << "unknown status #{@status}"
      @status = "report failure"
    end
  end
end

################################################################################
# END: Test Classes
#
#
################################################################################

################################################################################
# BEGIN: SS API
#
#
################################################################################
def gen_auth()
  options = get_options()
  auth = {"cookie" => {}, "authorization" => {}}
  
  if options.include?(:access_token)
    puts "Using pre-authenticated access token"
    puts "Logging into self service @ #{options[:selfservice_url]}"
    ss_login_req = RestClient::Request.new(
      :method => :get,
      :url => "#{options[:selfservice_url]}/api/catalog/new_session?account_id=#{options[:account_id]}",
      :headers => {"Authorization" => "Bearer #{options[:access_token]}"}
    )
    ss_login_resp = ss_login_req.execute
    auth["authorization"] = {"Authorization" => "Bearer #{options[:access_token]}"}
    return auth
  end
  
  if options.include?(:refresh_token)
    # OAuth
    puts "Logging into RightScale API 1.5 using OAuth @ #{options[:api_url]}"
    cm_login_req = RestClient::Request.new(
      :method => :post,
      :payload => URI.encode_www_form({
                                        :grant_type => "refresh_token",
                                        :refresh_token => options[:refresh_token]
                                      }),
      :url => "#{options[:api_url]}/api/oauth2",
      :headers => {"X-API-VERSION" => "1.5"}
    )
    cm_login_resp = cm_login_req.execute
    oauth_token = JSON.parse(cm_login_resp.to_s)["access_token"]
    puts "Logging into self service @ #{options[:selfservice_url]}"
    ss_login_req = RestClient::Request.new(
      :method => :get,
      :url => "#{options[:selfservice_url]}/api/catalog/new_session?account_id=#{options[:account_id]}",
      :headers => {"Authorization" => "Bearer #{oauth_token}"}
    )
    ss_login_resp = ss_login_req.execute
    auth["authorization"] = {"Authorization" => "Bearer #{oauth_token}"}
    return auth
  end
 
  if options.include?(:email) && options.include?(:password)
    puts "Logging into RightScale API 1.5 @ #{options[:api_url]}"
    cm_login_req = RestClient::Request.new(
      :method => :post,
      :payload => URI.encode_www_form({
        :email => options[:email],
        :password => options[:password],
        :account_href => "/api/accounts/#{options[:account_id]}"
      }),
      :url => "#{options[:api_url]}/api/session",
      :headers => {"X_API_VERSION" => "1.5"}
    )
    cm_login_resp = cm_login_req.execute

    puts "Logging into self service @ #{options[:selfservice_url]}"
    ss_login_req = RestClient::Request.new(
      :method => :get,
      :url => "#{options[:selfservice_url]}/api/catalog/new_session?account_id=#{options[:account_id]}",
      :cookies => {"rs_gbl" => cm_login_resp.cookies["rs_gbl"]}
    )
    ss_login_resp = ss_login_req.execute
    auth["cookie"] = cm_login_resp.cookies
    return auth
  end
  
  if options.include?(["instance_token"])
    raise "Sorry, don't think we can authenticate with SS using an instance token"
  end
  raise "No auth methods found"
end

def compile_template(auth, template_source)
  options = get_options()
  compile_req = RestClient::Request.new(
    :method => :post,
    :url => "#{options[:selfservice_url]}/api/designer/collections/#{options[:account_id]}/templates/actions/compile",
    :payload => URI.encode_www_form({
      "source" => template_source
    }),
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  compile_req.execute
end

def get_applications(auth)
  options = get_options()
  list_app_req = RestClient::Request.new(
    :method => :get,
    :url => "#{options[:selfservice_url]}/api/catalog/catalogs/#{options[:account_id]}/applications",
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  response = list_app_req.execute
  JSON.parse(response.body)
end

def get_templates(auth)
  options = get_options()
  list_req = RestClient::Request.new(
    :method => :get,
    :url => "#{options[:selfservice_url]}/api/designer/collections/#{options[:account_id]}/templates",
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  response = list_req.execute
  JSON.parse(response.body)
end

def get_cloudapps(auth)
  options = get_options()
  list_req = RestClient::Request.new(
    :method => :get,
    :url => "#{options[:selfservice_url]}/api/manager/projects/#{options[:account_id]}/executions",
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  response = list_req.execute
  JSON.parse(response.body)
end

def execution_create(template, auth, exec_options={})
  options = get_options()
  req = RestClient::Request.new(
    :method => :post,
    :url => "#{options[:selfservice_url]}/api/manager/projects/#{options[:account_id]}/executions",
    :cookies => auth["cookie"],
    :payload => URI.encode_www_form(
     :source => template
    ),
    #:timeout => 300,
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  req.execute
end

def execution_get_by_href(href, auth)
  options = get_options()
  req = RestClient::Request.new(
    :method => :get,
    :url => "#{options[:selfservice_url]}#{href}",
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  response = req.execute
  JSON.parse(response.body)
end

def execution_delete_by_href(href, auth)
  options = get_options()
  req = RestClient::Request.new(
    :method => :delete,
    :url => "#{options[:selfservice_url]}#{href}",
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  req.execute
end

def operation_create(execution_href, operation_name, auth, op_options={})
  options = get_options()
  req = RestClient::Request.new(
    :method => :post,
    :url => "#{options[:selfservice_url]}/api/manager/projects/#{options[:account_id]}/operations",
    :cookies => auth["cookie"],
    :payload => URI.encode_www_form(
      :name => operation_name,
      :execution_id => execution_id_from_href(execution_href)
    ),
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  req.execute
end

def operation_get_by_href(href, auth)
  options = get_options()
  req = RestClient::Request.new(
    :method => :get,
    :url => "#{options[:selfservice_url]}#{href}",
    :cookies => auth["cookie"],
    :headers => {"X_API_VERSION" => "1.0"}.merge(auth["authorization"])
  )
  response = req.execute
  JSON.parse(response.body)
end

################################################################################
# END: SS API
#
#
################################################################################

################################################################################
# BEGIN: Tasks
#
#
################################################################################

desc "Compile a template to discover any syntax errors"
task :template_compile, [:filepath] do |t,args|
  cat_str = preprocess_template(args[:filepath])
  begin
    puts "Uploading template to SS compile_template"
    compile_template(gen_auth(), cat_str)
    puts "Template compiled successfully"
  rescue RestClient::ExceptionWithResponse => e
    puts "Failed to compile template"
    errors = JSON.parse(e.http_body)
    puts JSON.pretty_generate(errors).gsub('\n',"\n")
  end
end

desc "Preprocess a template, replacing include:/path/to/file statements with file contents, and produce an output file.  Default output filepath is \"processed-\"+:input_filepath"
task :template_preprocess, [:input_filepath,:output_filepath] do |t,args|
  input_filedir = File.dirname(File.expand_path(args[:input_filepath]))
  input_filename = File.basename(args[:input_filepath])
  args.with_defaults(:output_filepath => File.join(input_filedir, "processed-#{input_filename}"))
  output_filepath = File.expand_path(args[:output_filepath])
  processed_template = preprocess_template(args[:input_filepath])
  File.open(File.expand_path(output_filepath), 'w') {|f| f.write(processed_template)}

  puts "Created a processed file at #{output_filepath}"
end

desc "Upload a new template or update an existing one (based on name)"
task :template_upsert, [:filepath] do |t,args|
  auth = gen_auth()
  href = template_upsert(args[:filepath],auth)
  puts "Template upserted. HREF: #{href}"
end

desc "Update and publish a template (based on name)"
task :template_publish, [:filepath] do |t,args|
  auth = gen_auth()
  href = template_publish(args[:filepath],auth)
  puts "Template published. HREF: #{href}"
end

desc "Update and re-publish a template (based on name)"
task :template_republish, [:filepath] do |t,args|
  auth = gen_auth()
  href = template_republish(args[:filepath],auth)
  puts "Template published. HREF: #{href}"
end

desc "List templates"
task :template_list do |t,args|
  auth = gen_auth()
  templates = get_templates(auth)
  puts JSON.pretty_generate(templates)
end

desc "List CloudApps"
task :cloudapp_list do |t,args|
  auth = gen_auth()
  puts JSON.pretty_generate(get_cloudapps(auth))
end

desc "Run Tests in the ./tests directory"
task :test, [:tests_glob] do |t,args|
  args.with_defaults(:tests_glob => "**/*.cat.rb")
  glob = File.join(File.expand_path("./tests"), args[:tests_glob])
  test_files = Dir.glob(glob)
  if test_files.length == 0
    puts "No test files found using glob (#{glob})"
    exit 0
  end

  auth = gen_auth()

  tests = []
  test_files.each do |test_file|
    tests << BaseTest.new(test_file,auth)
  end
  not_finished = true
  begin
    tests.each do |test|
      test.pump()
    end
    finished_tests = tests.select {|t| t.finished? }
    not_finished = tests.length > finished_tests.length
    sleep(10)
  end while not_finished

  failed_tests = tests.select {|t| t.status == "failed" }
  if failed_tests.length > 0
    Formatador.display_line("[_red_][black]Error Details[/]")
    failed_tests.each do |failed|
      failed.errors()
    end
  end
end

################################################################################
# END: Tasks
#
#
################################################################################
