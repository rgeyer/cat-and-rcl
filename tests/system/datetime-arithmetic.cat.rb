#test:execution_state=running
#test:execution_alternate_state=failed

name "datetime-arithmetic"
rs_ca_ver 20131202
short_description "Arithmetic operations on datetime objects seems to break RCL completely"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define launch() do
  $one_hour_in_seconds = 3600
  $created_at = to_d(10000)
  $now = now()
  $delta_native_type = $now - $created_at
end
