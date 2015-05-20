#test:execution_state=running
#test:execution_alternate_state=failed

name "non_global_overwrite"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define foo() do
  $not_global = {foo: "foo"}

  call baz()
  if $not_global != {foo: "foo"}
    raise "baz() overwrite a non global hash defined/declared in foo().  Expected $not_global to be {foo: foo} but it was "+to_s($not_global)
  end
end

define baz() do
  $not_global = {baz: "baz"}
end

define launch() do
  call foo()
end
