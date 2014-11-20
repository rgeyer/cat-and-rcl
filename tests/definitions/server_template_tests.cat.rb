#test:expected_state=running
#test_operation:can_find_in_any=completed
#test_operation:can_find_in_specific=completed
#test_operation:more_than_one_st_raises=comleted

name "server_template_tests"
rs_ca_ver 20131202
short_description "This is not an empty string"

parameter "rsb_st_name" do
  type "string"
  label "RSB ServerTemplate Name"
  default "Base ServerTemplate for Linux (RSB) (v13.5.5-LTS)"
end

parameter "chef_st_name" do
  type "string"
  label "Chef ServerTemplate Name"
  default "Base ServerTemplate for Linux (v13.5.5-LTS)"
end

parameter "rsb_boot_script_name" do
  type "string"
  label "RightScript name"
  default "SYS Timezone set - v13.5.3-LTS"
end

operation "can_find_in_any" do
  description "Can find a specified RightScript when no runlist is supplied"
  definition "can_find_in_any"
end

operation "can_find_in_specific" do
  description "Can find a specified RightScript when a specific runlist is supplied"
  definition "can_find_in_specific"
end

operation "more_than_one_st_raises" do
  description "Properly raises an error when more than one st is defined"
  definition "more_than_one_st_raises"
end

operation "returns_null_when_not_found" do
  description "Returns null when no RightScript is found"
  definition "returns_null_when_not_found"
end

#include:../../definitions/sys.cat.rb
#include:../../definitions/server_template.cat.rb

define get_st($name) return @st do
  @st = find("server_templates", $name)
  if empty?(@st)
    raise "Could not find '"+$name+"'.  Please import it into your account and try again"
  end
end

define get_both_sts($rsb_st_name, $chef_st_name) return @sts do
  call get_st($rsb_st_name) retrieve @st
  @sts = @st
  call get_st($chef_st_name) retrieve @st
  @sts = @sts + @st
end

define can_find_in_any($rsb_st_name,$rsb_boot_script_name) do
  call get_st($rsb_st_name) retrieve @st
  call server_template_get_rightscript_from_runnable_bindings(@st, $rsb_boot_script_name, {}) retrieve $href
  if $href == null
    raise "Did not find '"+$rsb_boot_script_name+"' in any runlist"
  end
end

define can_find_in_specific($rsb_st_name,$rsb_boot_script_name) do
  call get_st($rsb_st_name) retrieve @st
  call server_template_get_rightscript_from_runnable_bindings(@st, $rsb_boot_script_name, {runlist: "boot"}) retrieve $href
  if $href == null
    raise "Did not find '"+$rsb_boot_script_name+"' in the boot runlist"
  end
end

define more_than_one_st_raises_handler() do
  $expected_message = "server_template_get_rightscript_from_runnable_bindings() expects exactly one ServerTemplate in the @server_template parameter.  Got 2"
  if $_error["message"] != $expected_message
    raise "Wrong error message.  Expected: ("+$expected_message+") Got: ("+$_error["message"]+")"
  else
    $_error_behavior = "skip"
  end
end

define more_than_one_st_raises($rsb_st_name,$chef_st_name) do
  call get_both_sts($rsb_st_name,$chef_st_name) retrieve @sts
  sub on_error:more_than_one_st_raises_handler() do
    call server_template_get_rightscript_from_runnable_bindings(@sts, "foo", {}) retrieve $href
    raise "More than one ST in the collection, but no error was raised"
  end
end

define returns_null_when_not_found($rsb_st_name) do
  call get_st($rsb_st_name) retrieve @st
  call server_template_get_rightscript_from_runnable_bindings(@st, "foo", {}) retrieve $href
  if $href != null
    raise "No RightScript should have been found, href was set.  Expected: null Got: "+$href
  end
end
