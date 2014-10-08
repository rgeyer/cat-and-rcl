name "filters-ignored"
rs_ca_ver 20131202
short_description "Don\"t seem to be able to specify filters when fetching"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define launch() do
  concurrent foreach @cloud in rs.clouds.get() do
    # Filter syntax per -http://support.rightscale.com/12-Guides/Cloud_Workflow_Developer_Guide/01_Resources#Locating_Resources_of_a_Given_Type
    concurrent foreach @instance in @cloud.instances().get(filter: ["state<>inactive","state<>terminated"]) do
      call log("Found instance "+@instance.name+" in state "+@instance.state,"None")
    end
  end
end
