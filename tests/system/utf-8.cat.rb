#test:compile_only=true
#test:execution_state=running
#test:execution_alternate_state=failed

name "UTF-8 Test"
rs_ca_ver 20131202
short_description "Caché"

parameter "foo" do
  type "string"
  label "Foo"
  default "Caché"
  operations "launch"
end
