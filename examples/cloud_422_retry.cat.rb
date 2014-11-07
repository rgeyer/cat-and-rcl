name "cloud_422_retry"
rs_ca_ver 20131202
short_description "This is not an empty string"

resource "linux_base", type: "server" do
  name "linux"
  cloud_href "/api/clouds/1"
  instance_type "t2.small" # This will cause a 422, since we're not putting this in a VPC
  ssh_key "default"
  security_groups "default"
  server_template "Base ServerTemplate for Linux (v13.5.5-LTS)"
end

operation "launch" do
  description "scratch"
  definition "launch"
end

#include:../definitions/sys.cat.rb

define retry_mapper($retry_itr) do
  call retry_rotate_az_for_instance_capacity($az_list, @linux_base, $retry_itr) retrieve $az_list, @linux_base
end

define retry_rotate_az_for_instance_capacity($az_list, @server_def, $retry_itr) return $az_list, @server_def do
  # TODO: Validate that this is the right kind of error
  #422: CloudException: 500: InsufficientInstanceCapacity: We currently do not have sufficient t2.small capacity in the Availability Zone you requested (us-east-1d). Our system will be working on provisioning additional capacity. You can currently get t2.small capacity by not

  call sys_log("Error info", {detail: to_s($_error)})
  # if $_error["response_code"] != "422"
  #   raise "Attempted to handle a 422 error by retrying, but received a "+$_error["response_code"]+" error instead.  Try using an appropriate error handler"
  # end

  $server_def = to_object(@server_def)
  $next_az_href = ""
  @cloud = rs.get(href: from_json($server_def["fields"]["cloud_href"]))

  if contains?(keys($az_list), ["names"])
    if contains?(keys($server_def["fields"]), ["datacenter_href"])
      @datacenter = rs.get(href: from_json($server_def["fields"]["datacenter_href"]))
      $az_list["names"] = $az_list["names"] - [@datacenter.name]
    end
    $next_az_href = @cloud.datacenters(filter: ["name=="+first($az_list["names"])]).href
  elsif contains?(keys($az_list), ["hrefs"])

  else
    raise "Retry Rotate Availability Zone unable to determine AZ's from the $az_list parameter. "+to_s($az_list)
  end

  if $next_az_href == ""
    # TODO: Should I actually raise an exception, or let the standard handler run?
    raise "Tried launching ("+from_json($server_def["fields"]["name"])+") with all provided availability zones. Still received an insufficient capacity error.  "+$_error["message"]
  else
    $server_def["fields"]["datacenter_href"] = to_json($next_az_href)
    @server_def = $server_def
    $_error_behavior = "retry"
  end
end

define launch(@linux_base) do
  $az_list = {
    names: [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c",
      "us-east-1d",
      "us-east-1e"
    ]
  }
  # $az_list = {
  #   hrefs: [
  #     "/api/clouds/1/datacenters/CSADP6LN0D2K2",
  #     "/api/clouds/1/datacenters/8UO5L8B37J48C",
  #     "/api/clouds/1/datacenters/AMKO5F1M9E6M1",
  #     "/api/clouds/1/datacenters/EVPQ7H26PPK9M",
  #     "/api/clouds/1/datacenters/A3QAEU3SG4HMF"
  #   ]
  # }
  $retries = 0
  sub on_error: retry_mapper($retries) do
    call sys_log("AZ List", {detail: to_s($az_list)})
    call sys_log("Definition", {detail: to_s(to_object(@linux_base))})
    $retries = $retries + 1
    provision(@linux_base)
  end
end
