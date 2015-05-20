#test:execution_state=running
#test:execution_alternate_state=failed

name "to_object"
rs_ca_ver 20131202
short_description "to_object changed behavior on 11/20/2014"

#include:../../definitions/sys.cat.rb

resource "linux_base_1", type: "server" do
  name "linux"
  cloud_href "/api/clouds/1"
  instance_type "t2.small" # This causes failure because a VPC is required
  ssh_key "default"
  security_groups "default"
  server_template "Base ServerTemplate for Linux (v13.5.5-LTS)"
  inputs do {
    "foo" => "text:bar",
    "baz" => "cred:BARBAZ",
    "sys/swap_file" => "text:/mnt/ephemeral/swapfile"
  } end
end

operation "launch" do
  description "
  Previous behavior was that the \"inputs\" field could be evaluated with
  from_json() resulting in an object/hash of inputs in the inputs 2.0 format.

  I.E. {\"input1\":\"text:foo\",\"input2\":\"cred:FOO\"}

  New behavior is that the \"inputs\" field is an array of object/hash which
  is roughly equivalent to inputs 1.0 format.
  "
  definition "inputs_in_expected_format"
end

define inputs_in_expected_format(@linux_base_1) do
  $expectation_failures = []
  $object = to_object(@linux_base_1)
  call sys_log("inputs_in_expected_format",{detail: to_s($object)})
  $type = type($object["fields"]["inputs"])
  if $type != "object"
    $expectation_failures << "Expected the inputs in the result of to_object() to contain a single object"
  else
    $keys = keys($object["fields"]["inputs"])
    $key_count = size($keys)
    if $key_count != 3
      $expectation_failures << "Expected the inputs in the result of to_object() to contain exactly 3 key/value pairs but it had "+$key_count
    end
    $expected_keys = ["foo","baz","sys/swap_file"]
    if $keys != $expected_keys
      $expectation_failures << "Expected the inputs in the result of to_object() to contain these keys ("+to_s($expected_keys)+") but instead it had these keys ("+$keys+")"
    end
  end
  if !empty?($expectation_failures)
    raise join($expectation_failures, "\n\n")
  end
end
