#test:desired_state=running

name "only_string_for_hash_key"
rs_ca_ver 20131202
short_description "Not blank"

operation "launch" do
  description "do the things"
  definition "launch"
end

define launch() do
  $key = "foo"
  $val = "bar"

  $baz = {$key:$val}
  if contains?(keys($baz),["$key"])
    raise "Keys should contain \"foo\" but contained \"$key\""
  end
end
