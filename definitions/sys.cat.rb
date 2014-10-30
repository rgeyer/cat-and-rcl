# Creates a simple array of the specified size.  The array contains integers
# indexed from 1 up to the specified size
#
# @param $size [int] the desired number of elements in the returned array
#
# @return [Array] a 1 indexed array of the specified size
define get_array_of_size($size) return $array do
  $qty = 1
  $qty_ary = []
  while $qty <= to_n($size) do
    $qty_ary << $qty
    $qty = $qty + 1
  end

  $array = $qty_ary
end

# Logs a message in the "summary" field of an audit entry (limited to 255 char)
# with the CloudApp deployment as the auditee_href
#
# @param $message [String] the message to write in the "summary" field of an audit entry
# @param $notify [String] the event notification category, one of (None|Notification|Security|Error)
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceAuditEntries.html#create
define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

# Logs a message as an audit entry with the CloudApp deployment as the auditee_href
#
# @param $summary [String] the value to write in the "summary" field of an audit entry
# @param $details [String] the message to write in the "detail" field of an audit entry
# @param $notify [String] the event notification category, one of (None|Notification|Security|Error)
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceAuditEntries.html#create
define log_with_details($summary, $details, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $summary, detail: $details})
end

# Returns a resource collection containing clouds which have the specified relationship.
#
# @param $rel [String] the name of the relationship to filter on.  See cloud
#   media type for a full list
#
# @return [CloudResourceCollection] The clouds which have the specified relationship
#
# @see http://reference.rightscale.com/api1.5/media_types/MediaTypeCloud.html
define get_clouds_by_rel($rel) return @clouds do
  @clouds = concurrent map @cloud in rs.clouds.get() return @cloud_with_rel do
    $rels = select(@cloud.links, {"rel": $rel})
    if size($rels) > 0
      @cloud_with_rel = @cloud
    end
  end
end

# Fetches the execution id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The execution ID of the current cloud app
define get_execution_id() return $execution_id do
  call get_tags_for_resource(@@deployment) retrieve $tags_on_deployment
  $href_tag = concurrent map $current_tag in $tags_on_deployment return $tag do
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
