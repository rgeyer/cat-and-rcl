name 'output-map-must-assign-from-var'
rs_ca_ver 20131202
short_description <<EOF
Having an output mapping on a definition which does not get assigned from a
variable returned by that operation does not cause a parse/compile error, but
when attempting to launch the cloud app a cryptic message (in comments below)
is provided.

The following error occurred while trying to launch the CloudApp:
Problem: An internal error occurred. Summary: Error code: 1vciwapsg0qyp,
Issue: Problem: Validation of Model::Execution failed.
Summary: The following errors were found: Definitions is invalid
Resolution: Try persisting the document with valid data or remove the validations.
Resolution: Please contact RightScale support and report the error code provided in summary.
EOF

output "foo" do
  label "foo"
end

output "bar" do
  label "bar"
end

output "baz" do
  label "baz"
end

operation 'launch' do
  description 'launch'
  definition 'launch'
  output_mappings do {
    $foo => null, # This will cause it, on it's own
    $bar => '', # This too
    $baz => $retval, # This is the only acceptable syntax
  } end
end

define launch() return $retval do

end
