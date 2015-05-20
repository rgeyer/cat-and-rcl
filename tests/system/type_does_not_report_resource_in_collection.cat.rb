#test:execution_state=running
#test:execution_alternate_state=failed

name "type_does_not_report_resource_in_collection"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define launch() do
  @server_collection = rs.servers.empty()
  $type = type(@server_collection)
  if $type != "rs.servers"
    raise "Expected type() to return \"rs.servers\" for a server collection, got \""+$type+"\" instead."
  end
end
