# Converts a server to an rs.servers.create(server: $return_hash) compatible hash
#
# @param @server [ServerResourceCollection] a Server collection containing one
#   server (what happens if it contains more than one?) to be converted
#
# @return [Hash] a hash compatible with rs.servers.create(server: $return_hash)
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
  # TODO: Should be able to assign this directly in the "else" block above once
  # https://bookiee.rightscale.com/browse/SS-739 is fixed
  $media_type["instance"] = $instance_hash
end

# Launches a server and waits for it to become "operational" or "stranded"
#
# @param @server [ServerResourceCollection] The server(s) to launch and wait for
# @param $timeout [String] the desired timeout in the form specified by
#   (http://support.rightscale.com/12-Guides/Cloud_Workflow_Developer_Guide/04_Attributes_and_Error_Handling#Timeouts)
#   Also supports "none" for no timeout
define launch_and_wait(@server, $timeout) do
  @server.launch()
  if $timeout == "none"
    sleep_while(!contains?(@new_res.state,["operational","stranded"]))
  else
    sub timeout: $timeout do
      sleep_while(!contains?(@new_res.state,["operational","stranded"]))
    end
  end
end
