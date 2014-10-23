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
  $media_type = {"instance": {}}
  $instance_hash = {}
  foreach $key in keys($definition_hash["fields"]) do
    if contains?($top_level_properties, [$key])
      $media_type[$key] = from_json($definition_hash["fields"][$key])
    else
      $media_type["instance"][$key] = from_json($definition_hash["fields"][$key])
    end
  end
end

# Launches a server and waits for it to become "operational" or "stranded"
#
# @param @server [ServerResourceCollection] The server(s) to launch and wait for
# @param $timeout [String] the desired timeout in the form described in RCL
#   documentation.  Also supports "none" for no timeout
#
# @see http://support.rightscale.com/12-Guides/Cloud_Workflow_Developer_Guide/04_Attributes_and_Error_Handling#Timeouts RCL Documentation
define launch_and_wait(@server, $timeout) do
  @server.launch()
  if $timeout == "none"
    sleep_while(!any?(["operational","stranded"],@server.state))
  else
    sub timeout: $timeout do
      sleep_while(!any?(["operational","stranded"],@server.state))
    end
  end
end
