name "quantity"
rs_ca_ver 20131202
short_description "Launch a specified number of servers from Base ST"

parameter "qty_param" do
  type "number"
  label "Quantity"
  default 1
end

parameter "method_param" do
  type "string"
  label "Method"
  allowed_values "array","clone","multiprovision","rawdefinition","realraw"
end

resource "base_server_res", type: "server" do
  name "Base Linux"
  cloud_href "/api/clouds/1"
  ssh_key find(resource_uid: "default")
  security_groups find(name: "default")
  server_template find("Base ServerTemplate for Linux (RSB) (v13.5.5-LTS)", revision: 17)
end

resource "base_array_res", type: "server_array" do
  name "Base Linux"
  cloud_href "/api/clouds/1"
  ssh_key find(resource_uid: "default")
  security_groups find(name: "default")
  server_template find("Base ServerTemplate for Linux (RSB) (v13.5.5-LTS)", revision: 17)
  state "disabled"
  array_type "alert"
  elasticity_params do {
    "bounds" => {
      "min_count" => $qty_param,
      "max_count" => $qty_param
    },
    "pacing" => {
      "resize_calm_time" => 10,
      "resize_down_by" => 1,
      "resize_up_by" => 1
    },
    "alert_specific_params" => {
      "decision_threshold" => 51,
      "voters_tag_predicate" => "notdefined"
    }
  } end
end

operation "launch" do
  description "launch"
  definition "launch"
end

#include:../definitions/sys.cat.rb

define launch(@base_server_res,@base_array_res,$qty_param,$method_param) return @base_server_res,@base_array_res do
  call get_array_of_size($qty_param) retrieve $qty_ary
  if $method_param == "array"
    provision(@base_array_res)
  end

  if $method_param == "multiprovision"
    @@base_server_res = rs.servers.empty()
    $$definition_hash = to_object(@base_server_res)
    concurrent foreach $qty in $qty_ary do
      $definition_hash = $$definition_hash
      $definition_hash["fields"]["name"] = "foo-"+to_s($qty)
      # Change other things like inputs here
      @new_def = $definition_hash
      provision(@new_def)
    end
    @base_server_res = @@base_server_res
  end

  if $method_param == "clone"
    provision(@base_server_res)
    concurrent foreach $qty in $qty_ary do
      @new_res = @base_server_res.clone()
      @new_res.update(server: {name: "Cloned #"+$qty})
      # Change other things like inputs here
      @new_res.launch()
      sleep_while(@new_res.state != "operational")
    end
  end

  if $method_param == "rawdefinition"
    $$params = {
      "instance" => {
        "cloud_href" => "/api/clouds/1",
        "ssh_key_href" => "/api/clouds/1/ssh_keys/B393T34EO2K90",
        "security_group_hrefs" => ["/api/clouds/1/security_groups/7OSUUQ36RMKOP"],
        "server_template_href" => "/api/server_templates/341896004"
      }
    }
    concurrent foreach $qty in $qty_ary do
      $$params["name"] = "foo-"+to_s($qty)
      # Change other things like inputs here
      @resource_definition = {"namespace": "rs", "type": "servers", "fields": $$params}
      # Should this actually be
      # $resource_definition = {"namespace": "rs", "type": "servers", "fields": $$parms}
      # @resource_definition = $resource_definition
      provision(@resource_definition)
    end
  end

  if $method_param == "realraw"
    $$params = {
      "server" => {
        "deployment_href" => @@deployment.href,
        "instance" => {
          "cloud_href" => "/api/clouds/1",
          "ssh_key_href" => "/api/clouds/1/ssh_keys/B393T34EO2K90",
          "security_group_hrefs" => ["/api/clouds/1/security_groups/7OSUUQ36RMKOP"],
          "server_template_href" => "/api/server_templates/341896004"
        }
      }
    }
    concurrent foreach $qty in $qty_ary do
      $$params["server"]["name"] = "foo-"+to_s($qty)
      # Change other things like inputs here
      @server = rs.servers.create($$params)
      @server.launch()
      sleep_while(@server.state != "operational")
    end
  end
end
