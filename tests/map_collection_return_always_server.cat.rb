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
