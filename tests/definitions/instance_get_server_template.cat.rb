#test_operation:non_instance_raises=failed
#test_operation:instance_without_server_template_raises=failed

name "instance_get_server_template"
rs_ca_ver 20131202
short_description "This is not an empty string"

parameter "instance_without_st_param" do
  type "string"
  label "Instance HREF"
  description "The proper api href for an instance"
  allowed_pattern "/api/clouds/[0-9]+/instances/[0-9a-zA-Z]+"
end

operation "non_instance_raises" do
  description "Passing something other than instances fails"
  definition "non_instance_raises"
end

operation "instance_without_server_template_raises" do
  description "An instance that does not have a ServerTemplate fails"
  definition "instance_without_server_template_raises"
end

operation "foo" do
  description "foo"
  definition "foo"
end

#include:../../definitions/sys.cat.rb
#include:../../definitions/instance.cat.rb

define non_instance_raises() do
  @not_instances = rs.servers.empty()
  call instance_get_server_template(@not_instances) retrieve @serverTemplate
end

define instance_without_server_template_raises() do
  @instance = {"namespace": "rs", "type": "instances", "fields": {"links": [{"rel": "foo", "href": "/foo/bar/baz"}]}}
  call instance_get_server_template(@instance) retrieve @serverTemplate
end

define foo() do
  @instances = {"namespace": "rs", "type": "instances", "fields": {"links": [{"rel": "foo", "href": "/foo/bar/baz"}]}}
  call sys_log(to_s(@instances),{detail: to_json(@instances.links)})
end
