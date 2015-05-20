name "cloud_422_retry"
rs_ca_ver 20131202
short_description "This is not an empty string"

resource "linux_base1", type: "server" do
  name "linux"
  cloud_href "/api/clouds/1"
  instance_type "t2.small" # This will cause a 422, since we're not putting this in a VPC
  ssh_key "default"
  security_groups "default"
  server_template "Base ServerTemplate for Linux (v13.5.5-LTS)"
end

resource "linux_base2", type: "server" do
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

define retry_mapper1($retry_itr) do
  call retry_rotate_az_for_instance_capacity($az_list1, @linux_base1, $retry_itr) retrieve $az_list1, @linux_base1
end

define retry_mapper2($retry_itr) do
  call retry_rotate_az_for_instance_capacity($az_list2, @linux_base2, $retry_itr) retrieve $az_list2, @linux_base2
end

define retry_rotate_az_for_instance_capacity($az_list, @server_def_in, $retry_itr) return $az_list, @server_def_out do
  # TODO: Validate that this is the right kind of error
  #422: CloudException: 500: InsufficientInstanceCapacity: We currently do not have sufficient t2.small capacity in the Availability Zone you requested (us-east-1d). Our system will be working on provisioning additional capacity. You can currently get t2.small capacity by not

#   { type: failed_provision, message:
# Problem:
#   Provision failed
# Origin:
#   line: 120, column: 7
#     task: /root/2
#     expression: provision(server 'linux')
# Summary:
#   Failed to provision server 'linux' with: action 'launch' on /api/servers/1067047004 failed, request details:
#   POST https://us-4.<hidden credential>.com/api/servers/1067047004/launch
#
#   => 422: CloudException: 400: VPCResourceNotSpecified: The specified instance type can only be used in a VPC. A subnet ID or network interface ID is required to carry out the request. (RequestID: e381b4cb-5cf2-4bd2-98b3-0146de3fb139), origin: [120, 7] }

  call sys_log(task_name()+" Error info", {detail: to_s($_error)})
  # if $_error["response_code"] != "422"
  #   raise "Attempted to handle a 422 error by retrying, but received a "+$_error["response_code"]+" error instead.  Try using an appropriate error handler"
  # end

  $server_def = to_object(@server_def_in)
  $next_az_href = ""
  call sys_log(task_name()+" Server to obj is of type "+type($server_def), {detail: to_s($server_def)})
  @cloud = rs.get(href: $server_def["fields"]["cloud_href"])
  call sys_log(task_name()+" Cloud is... "+to_s(@cloud),{})

  @current_dc = rs.datacenters.empty()
  if contains?(keys($server_def["fields"]), ["datacenter_href"])
    @current_dc = rs.get(href: $server_def["fields"]["datacenter_href"])
  end

  if contains?(keys($az_list), ["names"])
    if !empty?(@current_dc)
      $az_list["names"] = $az_list["names"] - [@current_dc.name]
    end
    $next_az_href = @cloud.datacenters(filter: ["name=="+first($az_list["names"])]).href
  elsif contains?(keys($az_list), ["hrefs"])
    if !empty?(@current_dc)
      $az_list["hrefs"] = $az_list["hrefs"] - [@current_dc.href]
    end
  else
    raise "Retry Rotate Availability Zone unable to determine AZ's from the $az_list parameter. "+to_s($az_list)
  end

  if $next_az_href == ""
    # TODO: Should I actually raise an exception, or let the standard handler run?
    raise "Tried launching ("+$server_def["fields"]["name"]+") with all provided availability zones. Still received an insufficient capacity error.  "+$_error["message"]
  else
    $server_def["fields"]["datacenter_href"] = $next_az_href
    @server_def_out = $server_def
    $_error_behavior = "retry"
  end
end

define launch(@linux_base1,@linux_base2) do
  $az_list1 = {
    names: [
      "us-east-1a",
      "us-east-1b",
      "us-east-1c",
      "us-east-1d",
      "us-east-1e"
    ]
  }
  $az_list2 = {
    hrefs: [
      "/api/clouds/1/datacenters/CSADP6LN0D2K2",
      "/api/clouds/1/datacenters/8UO5L8B37J48C",
      "/api/clouds/1/datacenters/AMKO5F1M9E6M1",
      "/api/clouds/1/datacenters/EVPQ7H26PPK9M",
      "/api/clouds/1/datacenters/A3QAEU3SG4HMF"
    ]
  }

  $retries1 = 0
  $retries2 = 0
  concurrent do
    sub on_error: retry_mapper1($retries1), task_label: "Raise" do
      call sys_log(task_name()+" AZ List One", {detail: to_s($az_list1)})
      call sys_log(task_name()+" Definition One", {detail: to_s(to_object(@linux_base1))})
      $retries1 = $retries1 + 1
      raise "Problem:
        Provision failed
      Origin:
        line: 120, column: 7
          task: /root/2
          expression: provision(server 'linux')
      Summary:
        Failed to provision server 'linux' with: action 'launch' on /api/servers/1067047004 failed, request details:
        POST https://us-4.<hidden credential>.com/api/servers/1067047004/launch

        => 422: CloudException: 400: VPCResourceNotSpecified: The specified instance type can only be used in a VPC. A subnet ID or network interface ID is required to carry out the request. (RequestID: e381b4cb-5cf2-4bd2-98b3-0146de3fb139), origin: [120, 7]"
    end

    sub on_error: retry_mapper2($retries2), task_label: "Provision" do
      call sys_log(task_name()+" AZ List Two", {detail: to_s($az_list2)})
      call sys_log(task_name()+" Definition Two", {detail: to_s(to_object(@linux_base2))})
      $retries2 = $retries2 + 1
      provision(@linux_base2)
    end
  end
end
