#test:execution_state=running
#test:execution_alternate_state=failed

# TODO: Still no operations implemented
#operation:is_still_declaration=running

name "non_provisioned_resources_empty"
rs_ca_ver 20131202
short_description "When a CAT declaration of a resource is not provisioned by \"launch\" or \"auto-launch\" it becomes an empty server resource collection when accessed in custom operations"

#include:../../definitions/sys.cat.rb

resource "linux_base_1", type: "server" do
  name "linux"
  cloud_href "/api/clouds/1"
  instance_type "t2.small" # This causes failure
  ssh_key "default"
  security_groups "default"
  server_template "Base ServerTemplate for Linux (v13.5.5-LTS)"
end

operation "launch" do
  description "prevent auto-launch from provisioning the resource"
  definition "launch"
end

define launch(@linux_base_1) do
  # Just for fun, this is what it looks like in the launch operation
  call sys_log("Server Resource in Launch Operation",{detail: to_s(to_object(@linux_base_1))})
  # This results in;
  # { namespace: rs, type: servers, fields: { name: "linux", cloud_href: "/api/clouds/1", instance_type_href: eval("rs__find_cached", "instance_types", {"name":"t2.small", "cloud_href":"/api/clouds/1"}), ssh_key_href: eval("rs__find_cached", "ssh_keys", {"resource_uid":"default", "cloud_href":"/api/clouds/1"}), security_group_hrefs: [eval("rs__find_cached", "security_groups", eval("rs__add_default_network", {"name":"default", "cloud_href":"/api/clouds/1"}))], server_template_href: eval("rs__find_cached", "server_templates", {"name":"Base ServerTemplate for Linux (v13.5.5-LTS)"}), deployment_href: "/api/deployments/506776004" }, dependencies: [] }
end

operation "is_still_declaration" do
  description "The to_object() output still contains \"fields\" and \"fields\" still contains the name \"linux\""
  definition "is_still_declaration"
end

define is_still_declaration(@linux_base_1) do
  $expectation_failures = []
  $object = to_object(@linux_base_1)
  call sys_log("Server Resource in Custom Operation",{detail: to_s($object)})
  # This results in;
  # { namespace: rs, type: servers, hrefs: [], details: [] }
  if !contains?(keys($object),["fields"])
    $expectation_failures << "Expected the to_object() output for @linux_base_1 to contain fields, but it did not"
  else
    if !contains?(keys($object["fields"]),["name"])
      $expectation_failures << "Expected the to_object() output for @linux_base_1 to include fields/name but it did not"
    else
      if $object["fields"]["name"] != "linux"
        $expectation_failures << "Expected the to_object() output at fields/name for @linux_base_1 to equal \"linux\" but it did not"
      end
    end
  end

  if !empty?($expectation_failures)
    $expectation_failures << "Actual content of to_object() for @linux_base_1 was\n"+to_s($object)
    raise join($expectation_failures, "\n\n")
  end
end
