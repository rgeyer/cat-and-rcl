#test:desired_state=running

name "nil-maps"
rs_ca_ver 20131202
short_description "Maps which return no values result in a null return value, rather than an expected empty array (or resource collection)"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define launch() do
  $ary = [1,2,3,4]
  $foo = concurrent map $bar in $ary return $baz do

  end
  call sys_log("Map on an array which returns no values results in ("+to_json($foo)+") though I\"d expect it to be an empty array",{})

  if !empty?($foo)
    raise "Expected array to be empty"
  end

  @clouds = concurrent map @cloud in rs.clouds.get() return @selected_cloud do

  end
  call sys_log("Map on a resource collection of rs.clouds, which returns no values results in ("+type(@clouds)+") which is much better than null",{})
end
