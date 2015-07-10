name "RS1_3Tier"
rs_ca_ver 20131202
short_description "RS1_3Tier"

#include:../definitions/run_executable.cat.rb

mapping "cloud_to_stuff" do {
  "AWS" => {
    "instance_type" => "m3.medium"
  },
  "GCE" => {
    "instance_type" => "n1-standard-2"
  }
} end

operation "launch" do
  description "Custom Launch Logic"
  definition "launch"
end

define launch(@db, @lb1, @lb2, @app_array) return @db, @lb1, @lb2, @app_array do
  # $inputs = {
  #   "inputs": [
  #     {"ADMIN_PASSWORD": "cred:MICROSOFT_POLICY_PASSWORD"},
  #     {"BACKUP_FILE_NAME": "cred:BACKUP_FILE_NAME"},
  #     {"DATA_VOLUME_SIZE": "text:10"},
  #     {"DB_LINEAGE_NAME": "text:rs1lineage"},
  #     {"DB_NAME": "text:rs1_db"},
  #     {"DB_NEW_LOGIN_NAME": "cred:DBAPPLICATION_USER"},
  #     {"DNS_DOMAIN_NAME": "cred:RS01_FQDN"},
  #     {"DNS_ID": "cred:RS01_DDNSID"},
  #     {"DNS_PASSWORD": "cred:DNS_PASSWORD"},
  #     {"DNS_SERVICE": "text:DNS Made Easy"},
  #     {"DNS_USER": "cred:DNS_USER"},
  #     {"LOGS_VOLUME_SIZE": "text:10"},
  #     {"MASTER_KEY_PASSWORD": "cred:MICROSOFT_POLICY_PASSWORD"},
  #     {"REMOTE_STORAGE_ACCOUNT_ID": "cred:AWS_ACCESS_KEY_ID"},
  #     {"REMOTE_STORAGE_ACCOUNT_PROVIDER": "text:Amazon_S3"},
  #     {"REMOTE_STORAGE_ACCOUNT_SECRET": "cred:AWS_SECRET_ACCESS_KEY"},
  #     {"REMOTE_STORAGE_CONTAINER": "cred:DUMP_CONTAINER"},
  #     {"SYS_WINDOWS_TZINFO": "text:(UTC-08:00) Pacific Standard Time"},
  #     {"lb/session_stickiness": "text:false"},
  #     {"OPT_APP_POOL_NAME": "cred:OPT_APP_POOL_NAME"},
  #     {"OPT_CONNECTION_STRING_DB_NAME": "text:rs1_db"},
  #     {"OPT_CONNECTION_STRING_DB_SERVER_NAME": "cred:RS01_FQDN"},
  #     {"OPT_CONNECTION_STRING_DB_USER_ID": "cred:DBAPPLICATION_USER"},
  #     {"OPT_CONNECTION_STRING_DB_USER_PASSWORD": "cred:MICROSOFT_POLICY_PASSWORD"},
  #     {"OPT_CONNECTION_STRING_NAME": "cred:OPT_CONNECTION_STRING_NAME"},
  #     {"REMOTE_STORAGE_ACCOUNT_ID_APP": "cred:AWS_ACCESS_KEY_ID"},
  #     {"REMOTE_STORAGE_ACCOUNT_PROVIDER_APP": "text:Amazon_S3"},
  #     {"REMOTE_STORAGE_ACCOUNT_SECRET": "cred:AWS_SECRET_ACCESS_KEY"},
  #     {"REMOTE_STORAGE_ACCOUNT_SECRET_APP": "cred:AWS_SECRET_ACCESS_KEY"},
  #     {"ZIP_FILE_NAME": "cred:ZIP_FILE_NAME"}
  #   ]
  # }

  #@deployment = rs.deployments.get(href: @@deployment.href)

  #@deployment.inputs().multi_update($inputs)

  concurrent return @db, @lb1, @lb2, @app_array do
    provision(@db)
    provision(@lb1)
    provision(@lb2)
    provision(@app_array)
  end

  call run_executable(@db, {rightscript: {href: "/api/right_scripts/525054004"}}) retrieve @task
  call run_executable(@db, {rightscript: {href: "/api/right_scripts/525050004"}}) retrieve @task

end

define run_recipe(@target, $recipe_name) do
  @task = @target.current_instance().run_executable(recipe_name: $recipe_name, inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $recipe_name
  end
end


define run_rightscript_by_href(@target, $script_href) do
  @task = @target.current_instance().run_executable(right_script_href: $script_href, inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $recipe_name
  end
end

define run_rightscript_by_name(@target, $script_name) do
  @script = rs.right_scripts.index(latest_only: true, filter: ["name==" + $script_name])
  @task = @target.current_instance().run_executable(right_script_href: @script.href[0], inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $recipe_name
  end
end

resource "db", type: "server" do
  name "RS1_db"
  cloud "EC2 us-east-1"
  ssh_key find(resource_uid: "RS1_SSH", cloud_href: "/api/clouds/1")
  security_groups find("RS1_sg", cloud_href: "/api/clouds/1")
  server_template find("Database Manager for Microsoft SQL Server (13.5.1-LTS)", revision: 5)
  instance_type find(map($cloud_to_stuff, "AWS", "instance_type"), cloud_href: "/api/clouds/1")
  inputs do {
    "ADMIN_PASSWORD" => "cred:MICROSOFT_POLICY_PASSWORD",
    "BACKUP_FILE_NAME" => "cred:BACKUP_FILE_NAME",
    "DATA_VOLUME_SIZE" => "text:10",
    "DB_LINEAGE_NAME" => "text:rs1lineage",
    "DB_NAME" => "text:rs1_db",
    "DB_NEW_LOGIN_NAME" => "cred:DBAPPLICATION_USER",
    "DB_NEW_LOGIN_PASSWORD" => "cred:MICROSOFT_POLICY_PASSWORD",
    "DNS_DOMAIN_NAME" => "cred:RS01_FQDN",
    "DNS_ID" => "cred:RS01_DDNSID",
    "DNS_PASSWORD" => "cred:DNS_PASSWORD",
    "DNS_SERVICE" => "text:DNS Made Easy",
    "DNS_USER" => "cred:DNS_USER",
    "LOGS_VOLUME_SIZE" =>"text:10",
    "MASTER_KEY_PASSWORD" =>"cred:MICROSOFT_POLICY_PASSWORD",
    "REMOTE_STORAGE_ACCOUNT_ID" =>"cred:AWS_ACCESS_KEY_ID",
    "REMOTE_STORAGE_ACCOUNT_PROVIDER" =>"text:Amazon_S3",
    "REMOTE_STORAGE_ACCOUNT_SECRET" =>"cred:AWS_SECRET_ACCESS_KEY",
    "REMOTE_STORAGE_CONTAINER" =>"cred:DUMP_CONTAINER",
    "REMOTE_STORAGE_CONTAINER_APP" => "cred:DUMP_CONTAINER",
    "SYS_WINDOWS_TZINFO" =>"text:(UTC-08:00) Pacific Standard Time",
    "lb/session_stickiness" =>"text:false",
    "OPT_APP_POOL_NAME" =>"cred:OPT_APP_POOL_NAME",
    "OPT_CONNECTION_STRING_DB_NAME" =>"text:rs1_db",
    "OPT_CONNECTION_STRING_DB_SERVER_NAME" =>"cred:RS01_FQDN",
    "OPT_CONNECTION_STRING_DB_USER_ID" =>"cred:DBAPPLICATION_USER",
    "OPT_CONNECTION_STRING_DB_USER_PASSWORD" =>"cred:MICROSOFT_POLICY_PASSWORD",
    "OPT_CONNECTION_STRING_NAME" =>"cred:OPT_CONNECTION_STRING_NAME",
    "REMOTE_STORAGE_ACCOUNT_ID_APP" =>"cred:AWS_ACCESS_KEY_ID",
    "REMOTE_STORAGE_ACCOUNT_PROVIDER_APP" =>"text:Amazon_S3",
    "REMOTE_STORAGE_ACCOUNT_SECRET" =>"cred:AWS_SECRET_ACCESS_KEY",
    "REMOTE_STORAGE_ACCOUNT_SECRET_APP" =>"cred:AWS_SECRET_ACCESS_KEY",
    "ZIP_FILE_NAME" =>"cred:ZIP_FILE_NAME"
  } end
end

resource "lb1", type: "server" do
  name "rs1_lb1"
  cloud "EC2 us-east-1"
  datacenter find("us-east-1b", cloud_href: "/api/clouds/1")
  ssh_key find(resource_uid: "RS1_SSH", cloud_href: "/api/clouds/1")
  security_groups find("RS1_sg", cloud_href: "/api/clouds/1")
  server_template find("Load Balancer with HAProxy (v13.5.5-LTS)", revision: 18)
  instance_type find(map($cloud_to_stuff, "AWS", "instance_type"), cloud_href: "/api/clouds/1")
  inputs do {
    "ADMIN_PASSWORD" => "cred:MICROSOFT_POLICY_PASSWORD",
    "BACKUP_FILE_NAME" => "cred:BACKUP_FILE_NAME",
    "DATA_VOLUME_SIZE" => "text:10",
    "DB_LINEAGE_NAME" => "text:rs1lineage",
    "DB_NAME" => "text:rs1_db",
    "DB_NEW_LOGIN_NAME" => "cred:DBAPPLICATION_USER",
    "DB_NEW_LOGIN_PASSWORD" => "cred:MICROSOFT_POLICY_PASSWORD",
    "DNS_DOMAIN_NAME" => "cred:RS01_FQDN",
    "DNS_ID" => "cred:RS01_DDNSID",
    "DNS_PASSWORD" => "cred:DNS_PASSWORD",
    "DNS_SERVICE" => "text:DNS Made Easy",
    "DNS_USER" => "cred:DNS_USER",
    "LOGS_VOLUME_SIZE" =>"text:10",
    "MASTER_KEY_PASSWORD" =>"cred:MICROSOFT_POLICY_PASSWORD",
    "REMOTE_STORAGE_ACCOUNT_ID" =>"cred:AWS_ACCESS_KEY_ID",
    "REMOTE_STORAGE_ACCOUNT_PROVIDER" =>"text:Amazon_S3",
    "REMOTE_STORAGE_ACCOUNT_SECRET" =>"cred:AWS_SECRET_ACCESS_KEY",
    "REMOTE_STORAGE_CONTAINER" =>"cred:DUMP_CONTAINER",
    "REMOTE_STORAGE_CONTAINER_APP" => "cred:DUMP_CONTAINER",
    "SYS_WINDOWS_TZINFO" =>"text:(UTC-08:00) Pacific Standard Time",
    "lb/session_stickiness" =>"text:false",
    "OPT_APP_POOL_NAME" =>"cred:OPT_APP_POOL_NAME",
    "OPT_CONNECTION_STRING_DB_NAME" =>"text:rs1_db",
    "OPT_CONNECTION_STRING_DB_SERVER_NAME" =>"cred:RS01_FQDN",
    "OPT_CONNECTION_STRING_DB_USER_ID" =>"cred:DBAPPLICATION_USER",
    "OPT_CONNECTION_STRING_DB_USER_PASSWORD" =>"cred:MICROSOFT_POLICY_PASSWORD",
    "OPT_CONNECTION_STRING_NAME" =>"cred:OPT_CONNECTION_STRING_NAME",
    "REMOTE_STORAGE_ACCOUNT_ID_APP" =>"cred:AWS_ACCESS_KEY_ID",
    "REMOTE_STORAGE_ACCOUNT_PROVIDER_APP" =>"text:Amazon_S3",
    "REMOTE_STORAGE_ACCOUNT_SECRET" =>"cred:AWS_SECRET_ACCESS_KEY",
    "REMOTE_STORAGE_ACCOUNT_SECRET_APP" =>"cred:AWS_SECRET_ACCESS_KEY",
    "ZIP_FILE_NAME" =>"cred:ZIP_FILE_NAME"
  } end
end

resource "lb2", type: "server" do
  like "lb1"
  name "rs1_lb2"
end

resource "app_array", type: "server_array" do
  name "rs1_apparray"
  cloud "EC2 us-east-1"
  ssh_key find(resource_uid: "RS1_SSH", cloud_href: "/api/clouds/1")
  security_groups find("RS1_sg", cloud_href: "/api/clouds/1")
  server_template find("RS1 Microsoft IIS App Server (v13.5.0-LTS)", revision: 1)
  instance_type find(map($cloud_to_stuff, "AWS", "instance_type"), cloud_href: "/api/clouds/1")
  inputs do {
    "ADMIN_PASSWORD" => "cred:MICROSOFT_POLICY_PASSWORD",
    "BACKUP_FILE_NAME" => "cred:BACKUP_FILE_NAME",
    "DATA_VOLUME_SIZE" => "text:10",
    "DB_LINEAGE_NAME" => "text:rs1lineage",
    "DB_NAME" => "text:rs1_db",
    "DB_NEW_LOGIN_NAME" => "cred:DBAPPLICATION_USER",
    "DB_NEW_LOGIN_PASSWORD" => "cred:MICROSOFT_POLICY_PASSWORD",
    "DNS_DOMAIN_NAME" => "cred:RS01_FQDN",
    "DNS_ID" => "cred:RS01_DDNSID",
    "DNS_PASSWORD" => "cred:DNS_PASSWORD",
    "DNS_SERVICE" => "text:DNS Made Easy",
    "DNS_USER" => "cred:DNS_USER",
    "LOGS_VOLUME_SIZE" =>"text:10",
    "MASTER_KEY_PASSWORD" =>"cred:MICROSOFT_POLICY_PASSWORD",
    "REMOTE_STORAGE_ACCOUNT_ID" =>"cred:AWS_ACCESS_KEY_ID",
    "REMOTE_STORAGE_ACCOUNT_PROVIDER" =>"text:Amazon_S3",
    "REMOTE_STORAGE_ACCOUNT_SECRET" =>"cred:AWS_SECRET_ACCESS_KEY",
    "REMOTE_STORAGE_CONTAINER" =>"cred:DUMP_CONTAINER",
    "REMOTE_STORAGE_CONTAINER_APP" => "cred:DUMP_CONTAINER",
    "SYS_WINDOWS_TZINFO" =>"text:(UTC-08:00) Pacific Standard Time",
    "lb/session_stickiness" =>"text:false",
    "OPT_APP_POOL_NAME" =>"cred:OPT_APP_POOL_NAME",
    "OPT_CONNECTION_STRING_DB_NAME" =>"text:rs1_db",
    "OPT_CONNECTION_STRING_DB_SERVER_NAME" =>"cred:RS01_FQDN",
    "OPT_CONNECTION_STRING_DB_USER_ID" =>"cred:DBAPPLICATION_USER",
    "OPT_CONNECTION_STRING_DB_USER_PASSWORD" =>"cred:MICROSOFT_POLICY_PASSWORD",
    "OPT_CONNECTION_STRING_NAME" =>"cred:OPT_CONNECTION_STRING_NAME",
    "REMOTE_STORAGE_ACCOUNT_ID_APP" =>"cred:AWS_ACCESS_KEY_ID",
    "REMOTE_STORAGE_ACCOUNT_PROVIDER_APP" =>"text:Amazon_S3",
    "REMOTE_STORAGE_ACCOUNT_SECRET" =>"cred:AWS_SECRET_ACCESS_KEY",
    "REMOTE_STORAGE_ACCOUNT_SECRET_APP" =>"cred:AWS_SECRET_ACCESS_KEY",
    "ZIP_FILE_NAME" =>"cred:ZIP_FILE_NAME"
  } end
  state "disabled"
  array_type "alert"
  elasticity_params do {
    "bounds" => {
      "min_count"            => 1,
      "max_count"            => 5
    },
    "pacing" => {
      "resize_calm_time"     => 10,
      "resize_down_by"       => 1,
      "resize_up_by"         => 1
    },
    "alert_specific_params" => {
      "decision_threshold"   => 51,
      "voters_tag_predicate" => "rs1_apparray"
    }
  } end
end
