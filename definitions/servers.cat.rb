define server_definition_to_media_type(@server) return $media_type do
  $top_level_properties = [
    "deployment_href",
    "description",
    "name",
    "optimized"
  ]
  $definition_hash = to_object(@server)
  $media_type = {}
  $instance_hash = {}
  foreach $key in keys($definition_hash["fields"]) do
    call log_with_details("Key "+$key, $key+"="+to_json($definition_hash["fields"][$key]), "None")
    if contains?($top_level_properties, [$key])
      $media_type[$key] = $definition_hash["fields"][$key]
    else
      $instance_hash[$key] = $definition_hash["fields"][$key]
    end
  end
  $media_type["instance"] = $instance_hash
end
