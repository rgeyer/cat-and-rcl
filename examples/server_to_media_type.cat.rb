name "server_to_media_type"
rs_ca_ver 20131202
short_description "Do some cool stuff converting a CAT server declaration into other stuff"

resource "base_server_res", type: "server" do
  name "Base Linux"
  cloud_href "/api/clouds/1"
  ssh_key "default"
  security_groups "default"
  server_template find("Base ServerTemplate for Linux (RSB) (v13.5.5-LTS)", revision: 17)
end

operation "launch" do
  description "launch"
  definition "launch"
end

#include:../definitions/sys.cat.rb

#include:../definitions/servers.cat.rb

define launch(@base_server_res) return @base_server_res do
  call server_definition_to_media_type(@base_server_res) retrieve $media_type
  call log_with_details("Converted Definition", to_json($media_type), "None")
  @new_server = rs.servers.create(server: $media_type)
end
