name "hash"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

#include:../definitions/sys.cat.rb

define launch() do
  $default = {
    foo: true,
    bar: {
      baz: false
    }
  }
  $override = {
    bar: {
      baz: true
    }
  }

  $result = $override + $default
  call sys_log("hash",{detail: "The hash is "+to_s($result)})
end
