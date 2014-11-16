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

# Fetches the execution id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The execution ID of the current cloud app
define sys_get_execution_id() return $execution_id do
  call get_tags_for_resource(@@deployment) retrieve $tags_on_deployment
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
