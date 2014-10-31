name "map_collection_return_always_server"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define launch() do
  @scripts = rs.right_scripts.get(filter: ["name==CAT - run_executable test"])
  $revisions, @head_rev_script = concurrent map @script in @scripts return $return_revision, @return_script do
    $return_revision = @script.revision
    if to_s(@script.revision) == "0"
      @return_script = @script
    end
  end
end

# This results in
# launch failed:
#
# Problem:
#   Resource collection type mismatch
# Origin:
#   line: 26, column: 34
#     task: /root
#     expression:
#     $revisions, @head_rev_script = concurrent map @script in @scripts return $return_revision, @return_script do
#     |   $return_revision = @script.revision
#     |   if to_s(@script.revision) == "0"
#     |   |   @return_script = @script
#     |   end
#     end
# Summary:
#   Cannot concatenate a resource collection of rs.right_scripts to a resource collection of rs.servers (types must match)
# Resolution:
#   Make sure resource collection types match


# If I remove the if statement from the map, such that every iteration assigns
# something to @return_script, the error goes away.  I'm not sure what causes it
# but it is reproducible
