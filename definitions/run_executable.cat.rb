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
