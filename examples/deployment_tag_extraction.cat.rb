name "DeploymentTagExtraction"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "launch" do
  description "Do the stuff"
  definition "launch"
  output_mappings do {
    $href => $href1,
    $execution_id => $execution_id1,
    $account_id => $account_id1,
    $launched_by => $launched_by1,
    $launched_from => $launched_from1,
    $launched_from_type => $launched_from_type1
  } end
end

#include:../definitions/sys.cat.rb

#include:../definitions/tag.cat.rb

output "href" do
  label "CloudApp Href"
  description "CloudApp Href"
end

output "execution_id" do
  label "CloudApp Execution Id"
  description "CloudApp Execution Id"
end

output "account_id" do
  label "Account Id"
  description "Account Id"
end

output "launched_by" do
  label "CloudApp Launched By"
  description "CloudApp Launched By"
end

output "launched_from" do
  label "CloudApp Launched From"
  description "CloudApp Launched From"
end

output "launched_from_type" do
  label "CloudApp Launched From Type"
  description "CloudApp Launched From Type"
end

define launch() return $href1, $execution_id1, $account_id1, $launched_by1, $launched_from1, $launched_from_type1 do
  $href1 = "Undefined"
  $execution_id1 = "Undefined"
  $account_id1 = "Undefined"
  $launched_by1 = "Undefined"
  $launched_from1 = "Undefined"
  $launched_from_type1 = "Undefined"
  call sys_get_execution_id() retrieve $execution_id1
  call sys_get_account_id() retrieve $account_id1
  call sys_get_href() retrieve $href1
  call sys_get_launched_by() retrieve $launched_by1
  call sys_get_launched_from() retrieve $launched_from1
  call sys_get_launched_from_type() retrieve $launched_from_type1
end
