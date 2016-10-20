# Creates a simple array of the specified size.  The array contains integers
# indexed from 1 up to the specified size
#
# @param $size [int] the desired number of elements in the returned array
#
# @return [Array] a 1 indexed array of the specified size
define sys_get_array_of_size($size) return $array do
  $qty = 1
  $qty_ary = []
  while $qty <= to_n($size) do
    $qty_ary << $qty
    $qty = $qty + 1
  end

  $array = $qty_ary
end

# Creates a "log" entry in the form of an audit entry.  The target of the audit
# entry defaults to the deployment created by the CloudApp, but can be specified
# with the "auditee_href" option.
#
# @param $summary [String] the value to write in the "summary" field of an audit entry
# @param $options [Hash] a hash of options where the possible keys are;
#   * detail [String] the message to write to the "detail" field of the audit entry. Default: ""
#   * notify [String] the event notification catgory, one of (None|Notification|Security|Error).  Default: None
#   * auditee_href [String] the auditee_href (target) for the audit entry. Default: @@deployment.href
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceAuditEntries.html#create
define sys_log($summary,$options) do
  $log_default_options = {
    detail: "",
    notify: "None",
    auditee_href: @@deployment.href
  }

  $log_merged_options = $options + $log_default_options
  rs.audit_entries.create(
    notify: $log_merged_options["notify"],
    audit_entry: {
      auditee_href: $log_merged_options["auditee_href"],
      summary: $summary,
      detail: $log_merged_options["detail"]
    }
  )
end

# Returns a resource collection containing clouds which have the specified relationship.
#
# @param $rel [String] the name of the relationship to filter on.  See cloud
#   media type for a full list
#
# @return [CloudResourceCollection] The clouds which have the specified relationship
#
# @see http://reference.rightscale.com/api1.5/media_types/MediaTypeCloud.html
define sys_get_clouds_by_rel($rel) return @clouds do
  @clouds = concurrent map @cloud in rs.clouds.get() return @cloud_with_rel do
    $rels = select(@cloud.links, {"rel": $rel})
    if size($rels) > 0
      @cloud_with_rel = @cloud
    else
      @cloud_with_rel = rs.clouds.empty()
    end
  end
end

# Fetches the account id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The account ID of the current cloud app
define sys_get_account_id() return $account_id do
  call sys_get_account_id_of_deployment(@@deployment) retrieve $account_id
end

# Fetches the account id of any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the account ID for.
#
# @return [String] The account ID of the cloud app for the specified deployment
define sys_get_account_id_of_deployment(@deployment) return $account_id do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $tag_value = last($tag_split_by_value_delimiter)
    $value_split_by_slashes = split($tag_value, "/")
    $account_id = $value_split_by_slashes[4]
  else
    $account_id = "N/A"
  end
end

# Fetches the execution id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The execution ID of the current cloud app
define sys_get_execution_id() return $execution_id do
  call sys_get_execution_id_of_deployment(@@deployment) retrieve $execution_id
end

# Fetches the execution id of any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the execution ID for.
#
# @return [String] The execution ID of the cloud app for the specified deployment
define sys_get_execution_id_of_deployment(@deployment) return $execution_id do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $tag_value = last($tag_split_by_value_delimiter)
    $value_split_by_slashes = split($tag_value, "/")
    $execution_id = last($value_split_by_slashes)
  else
    $execution_id = "N/A"
  end

end

# Fetches the href of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The href of the current cloud app
define sys_get_href() return $href do
  call sys_get_href_of_deployment(@@deployment) retrieve $href
end

# Fetches the href of any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the href for.
#
# @return [String] The href of the cloud app for the specified deployment
define sys_get_href_of_deployment(@deployment) return $href do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $href = last($tag_split_by_value_delimiter)
  else
    $href = "N/A"
  end

end

# Fetches the email/username of the user who launched "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:launched_by=foo@bar.baz
#
# @return [String] The email/username of the user who launched the current cloud app
define sys_get_launched_by() return $launched_by do
  call sys_get_launched_by_of_deployment(@@deployment) retrieve $launched_by
end

# Fetches the email/username of the user who launched any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:launched_by=foo@bar.baz
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the launched by user for.
#
# @return [String] The email/username of the user who launched the cloud app for the specified deployment
define sys_get_launched_by_of_deployment(@deployment) return $launched_by do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:launched_by)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $launched_by = last($tag_split_by_value_delimiter)
  else
    $launched_by = "N/A"
  end

end

# Fetches the name of the template "this" cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from=foobarbaz
#
# @return [String] The name of the template used to launch the current cloud app
define sys_get_launched_from() return $launched_from do
  call sys_get_launched_from_of_deployment(@@deployment) retrieve $launched_from
end

# Fetches the name of the template any cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from=foobarbaz
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the template used to launch the cloud app that owns it.
#
# @return [String] The name of the template used to launch the cloud app for the specified deployment
define sys_get_launched_from_of_deployment(@deployment) return $launched_from do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:launched_from)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $launched_from = last($tag_split_by_value_delimiter)
  else
    $launched_from = "N/A"
  end

end

# Fetches the type of the template "this" cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from_type=source
#
# @return [String] The type of the template used to launch the current cloud app
define sys_get_launched_from_type() return $launched_from_type do
  call sys_get_launched_from_type_of_deployment(@@deployment) retrieve $launched_from_type
end

# Fetches the type of the template any cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from_type=source
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the type of template used to launch the cloud app that owns it.
#
# @return [String] The type of the template used to launch the cloud app for the specified deployment
define sys_get_launched_from_type_of_deployment(@deployment) return $launched_from_type do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:launched_from_type)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $launched_from_type = last($tag_split_by_value_delimiter)
  else
    $launched_from_type = "N/A"
  end

end

# Concurrently finds and deletes all servers and arrays. Useful as a replacement
# for auto-terminate to clean up more quickly.
define sys_concurrent_terminate_servers_and_arrays() do
  concurrent do
    sub task_name:"terminate servers" do
      concurrent foreach @server in @@deployment.servers() do
        delete(@server)
      end
    end

    sub task_name:"terminate server_arrays" do
      concurrent foreach @array in @@deployment.server_arrays() do
        delete(@array)
      end
    end
  end
end

# Used as an alternative to provision(@resource), this will create the specified
# resource, but not launch it. Intended for use with Servers and ServerArrays
#
# @param @resource [Server|ServerArray] the resource definition to be created,
#   but not launched
#
# @return [Server|ServerArray] the created resource
define sys_create_resource_only(@resource) return @created_resource do
  $resource = to_object(@resource)
  $resource_type = $resource["type"]
  $fields = $resource["fields"]
  @created_resource = rs.$resource_type.create($fields)
end
