define run_recipe(@target, $recipe_name) do
  @task = @target.current_instance().run_executable(recipe_name: $recipe_name, inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $recipe_name
  end
end

define run_recipe_with_inputs(@target, $recipe_name, $inputs) do
  @task = @target.current_instance().run_executable(recipe_name: $recipe_name, inputs: $inputs)
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $recipe_name
  end
end

define run_rightscript_by_href(@target, $script_href) do
  @task = @target.current_instance().run_executable(right_script_href: $script_href, inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $script_href
  end
end

define run_rightscript_by_href_with_inputs(@target, $script_href, $inputs) do
  @task = @target.current_instance().run_executable(right_script_href: $script_href, inputs: $inputs)
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $script_href
  end
end

define run_rightscript_by_name(@target, $script_name) do
  @script = rs.right_scripts.index(latest_only: "true", filter: ["name=="+$script_name])
  @task = @target.current_instance().run_executable(right_script_href: @script.href, inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $script_name
  end
end

define run_rightscript_by_name_with_inputs(@target, $script_name, $inputs) do
  @script = rs.right_scripts.index(latest_only: "true", filter: ["name=="+$script_name])
  @task = @target.current_instance().run_executable(right_script_href: @script.href, inputs: $inputs)
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $script_name
  end
end

# Run a rightscript or recipe on a server or instance collection.
#
# @param @target [ServerResourceCollection|InstanceResourceCollection] the
#   resource collection to run the executable on.
# @param $options [Hash] a hash of options where the possible keys are;
#   * ignore_lock [Bool] whether to run the executable even when the instance
#     is locked.  Default: false
#   * wait_for_completion [Bool] Whether this definition should block waiting for
#     the executable to finish running or fail.  Default: true
#   * inputs [Hash] the inputs to pass to the run_executable request.  Default: {}
#   * rightscript [Hash] a hash of rightscript details where the possible keys are;
#     * name [String] the name of the rightscript to execute
#     * revision [Int] the revision number of the rightscript to run.
#       If not supplied the "latest" (which could be HEAD) will be used.
#     * href [String] if specified href takes prescedence and defines the *exact*
#       rightscript and revision to execute
#   * recipe [String] the recipe name to execute (must be associated with the
#     @target's ServerTemplate)
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceInstances.html#multi_run_executable
define run_executable(@target,$options) return @tasks do
  @tasks = rs.tasks.empty()
  $default_options = {
    ignore_lock: false,
    wait_for_completion: true,
    inputs: {}
  }

  $merged_options = $options + $default_options

  # TODO: type() always returns just "collection" reported as line 11 in the doc
  # https://docs.google.com/a/rightscale.com/spreadsheets/d/1zEqFvhLDygFdxm588LGrHshpBgp41xvIeqjEVigdHto/edit#gid=0
  @instances = rs.instances.empty()
  $target_type = to_s(@target)
  #$target_type = type(@target)
  #if $target_type == "rs.servers"
  if $target_type =~ "servers"
    @instances = @target.current_instance()
  #elsif $target_type == "rs.instances"
  elsif $target_type =~ "instances"
    @instances = @target
  else
    raise "run_executable() can not operate on a collection of type "+$target_type
  end

  $run_executable_params_hash = {inputs: $merged_options["inputs"]}
  if contains?(keys($merged_options),["rightscript"])
    if any?(keys($merged_options["rightscript"]),"/(name|href)/")
      if contains?(keys($merged_options["rightscript"]),["href"])
        $run_executable_params_hash["right_script_href"] = $merged_options["rightscript"]["href"]
      else
        @scripts = rs.right_scripts.get(filter: ["name=="+$merged_options["rightscript"]["name"]])
        if empty?(@scripts)
          raise "run_executable() unable to find RightScript with the name "+$merged_options["rightscript"]["name"]
        end
        $revision = $merged_options["rightscript"]["revision"] || 0
        $revisions, @script_to_run = concurrent map @script in @scripts return $available_revision, @script_with_revision do
          $available_revision = @script.revision
          if $available_revision == $revision
            @script_with_revision = @script
          end
        end
        if empty?(@script_to_run)
          raise "run_executable() found the script named "+$merged_options["rightscript"]["name"]+" but revision "+$revision+" was not found.  Available revisions are "+to_s($revisions)
        end
        $run_executable_params_hash["right_script_href"] = @script_to_run.href
      end
    else
      raise "run_executable() requires either 'name' or 'href' when executing a RightScript.  Found neither."
    end
  elsif contains?(keys($merged_options),["recipe"])
    $run_executable_params_hash["recipe_name"] = $merged_options["recipe"]
  else
    raise "run_executable() requires either 'rightscript' or 'recipe' in the $options.  Found neither."
  end

  @tasks = @instances.run_executable($run_executable_params_hash)

  if $merged_options["wait_for_completion"]
    sleep_until(@tasks.summary =~ "^(completed|failed)")
    if @tasks.summary =~ "failed"
      raise "Failed to run " + $script_name
    end
  end
end
