#name "RightScale Showcase"
rs_ca_ver 20131202
short_description "RightScale Showcase"

parameter "region_param" do
  type "string"
  label "Region"
  allowed_values "Sydney", "Singapore", "Tokyo", "Oregon", "San Jose", "New Jersey", "Sao Paulo", "EU"
  default "Sydney"
  operations "launch"
end

parameter "admin_pass_param" do
  type "string"
  no_echo "true"
  label "Administrator Password"
  description "Password which will be set for the local administrator account"
  min_length "7"
  allowed_pattern "^(?=.*[0-9])(?=.*[a-zA-Z])([a-zA-Z0-9]+)$"
  constraint_description "This should be at least 7 characters long with at least one upper case letter, one lower case letter and one digit.  Because I'm lazy, no special chars are allowed."
  operations "launch"
end

parameter "performance_param" do
  type "string"
  label "Performance Profile"
  allowed_values "high", "low"
  default "low"
  operations "launch"
end

output "base_public_ip_output" do
  label "Base Windows Public IP"
  category "Connectivity"
  #description "Base Windows Public IP"
end

output "base_private_ip_output" do
  label "Base Windows Private IP"
  category "Connectivity"
  #description "Base Windows Private IP"
end

output "db_public_ip_output" do
  label "Database Public IP"
  category "Connectivity"
  #description "Database Public IP"
end

output "db_private_ip_output" do
  label "Database Private IP"
  category "Connectivity"
  #description "Database Private IP"
end

output "master_key_pass_output" do
  label "Master DB Replication Key Password"
  category "Secrets"
  #description "Master DB Replication Key Password"
end

# Inputs:
# Cloud Regions - All Regions with Sydney as Default
# Performance Profile Mapping - EC2 Instance Type
# Admin / Password for Windows with Validation
# [Custom] Local Hostname - Text Field
#
# Outputs:
# ServerStatus Indicator
# Public IP
# Private IP
# Master Key Passwd
#
# Manually RDP
#
#
# If we have time:
# SSRS
# Join AD - DNS Servers

# These are deliberately identical, but could be different
mapping "performance_map" do {
  "low" => {
    "db_instance_type" => "m3.medium",
    "base_instance_type"  => "t2.small",
  },
  "high" => {
    "db_instance_type" => "m3.medium",
    "base_instance_type"  => "t2.small",
  },
} end

mapping "cloud_map" do {
  "Sydney" => {
    "cloud_href" => "/api/clouds/8",
  },
  "Singapore"=> {
    "cloud_href" => "/api/clouds/4",
  },
  "Tokyo"=> {
    "cloud_href" => "/api/clouds/8",
  },
  "Oregon"=> {
    "cloud_href" => "/api/clouds/8",
  },
  "San Jose"=> {
    "cloud_href" => "/api/clouds/8",
  },
  "New Jersey"=> {
    "cloud_href" => "/api/clouds/8",
  },
  "Sao Paulo"=> {
    "cloud_href" => "/api/clouds/8",
  },
  "EU"=> {
    "cloud_href" => "/api/clouds/8",
  },
} end

resource "server_1", type: "server" do
  name "Base ServerTemplate for Windows (v13.5.0-LTS)"
  cloud_href map("cloud_map", $region_param, "cloud_href")
  datacenter "ap-southeast-2a"
  ssh_key "rightscale-showcase"
  subnets find(resource_uid: "subnet-9016f9e7", network_href: "/api/networks/BAL2H1TCLKQTI")
  security_groups "rightscale-showcase"
  server_template find("Base ServerTemplate for Windows (v13.5.0-LTS)", revision: 3)
  instance_type find(map("performance_map", $performance_param, "base_instance_type"))
  multi_cloud_image_href "/api/multi_cloud_images/383584004"
  inputs do {
    "KMS_PORT" => "text:1688",
    "WINDOWS_AUTOMATIC_UPDATES_POLICY" => "text:Disable automatic updates",
    "WINDOWS_UPDATES_REBOOT_SETTING" => "text:Do Not Allow Reboot",
  } end
end

resource "server_2", type: "server" do
  name "Database Manager for Microsoft SQL Server (13.5.1-LTS)"
  cloud_href map("cloud_map", $region_param, "cloud_href")
  datacenter "ap-southeast-2a"
  ssh_key "rightscale-showcase"
  subnets find(resource_uid: "subnet-9016f9e7", network_href: "/api/networks/BAL2H1TCLKQTI")
  security_groups "rightscale-showcase"
  server_template find("Database Manager for Microsoft SQL Server (13.5.1-LTS)", revision: 5)
  instance_type find(map("performance_map", $performance_param, "db_instance_type"))
  multi_cloud_image_href "/api/multi_cloud_images/383591004"
  inputs do {
    "DATA_VOLUME_SIZE" => "text:10",
    "DB_BACKUP_FREQUENCY" => "text:4",
    "DB_LINEAGE_NAME" => "text:rightscale-showcase",
    "DNS_TTL" => "text:60",
    "ENABLE_TLOG_BACKUPS_BEFORE_SNAPSHOT" => "text:True",
    "KMS_PORT" => "text:1688",
    "LOGS_VOLUME_SIZE" => "text:10",
    "REMOTE_STORAGE_BLOCK_SIZE" => "text:10",
    "REMOTE_STORAGE_THREAD_COUNT" => "text:2",
    "SKIP_RESTORE_SYSTEM_DATABASES" => "text:False",
    "USE_PUBLIC_IP_WITNESS" => "text:False",
    "WINDOWS_AUTOMATIC_UPDATES_POLICY" => "text:Disable automatic updates",
    "WINDOWS_UPDATES_REBOOT_SETTING" => "text:Do Not Allow Reboot",
  } end
end

operation "launch" do
  description "Launch the application"
  definition "generated_launch"
  output_mappings do {
    $base_public_ip_output => @server_1.public_ip_address,
    $base_private_ip_output => @server_1.private_ip_address,
    $db_public_ip_output => @server_2.public_ip_address,
    $db_private_ip_output => @server_2.private_ip_address,
    $master_key_pass_output => $master_key_pass,
  } end
end

define generated_launch(@server_1, @server_2, $admin_pass_param) return @server_1, @server_2, $master_key_pass do
  $master_key_pass = uuid()
  $inp = {
    "SYS_WINDOWS_TZINFO": "text:(UTC+10:00) West Pacific Standard Time",
    "ADMIN_PASSWORD": join(["text:",$admin_pass_param]),
    "MASTER_KEY_PASSWORD": join(["text:",$master_key_pass])
  }
  @@deployment.multi_update_inputs(inputs: $inp)
  @@global_server_1 = @server_1
  @@global_server_2 = @server_2
  concurrent do
    provision(@@global_server_1)
    provision(@@global_server_2)
  end
  @server_1 = @@global_server_1
  @server_2 = @@global_server_2
end
