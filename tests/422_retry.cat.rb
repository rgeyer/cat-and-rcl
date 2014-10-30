name "Scratch CAT"
rs_ca_ver 20131202
short_description "Scratch CAT"

operation "launch" do
  description "scratch"
  definition "launch"
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define retry_422_resource_not_found($max_retries, $retries) do
  # if $_error["response_code"] != "422"
  #   raise "Attempted to handle a 422 error by retrying, but received a "+$_error["response_code"]+" error instead.  Try using an appropriate error handler"
  # end
  if $retries < $max_retries
    $_error_behavior = "retry"
  else
    #raise "Failed to find resource "+$_error["resource_href"]+" after "+$retries+" retries"
    raise "Failed to find resource after "+$retries+" retries"
  end
end

define launch() do
  $deployment_get_retries = 0
  sub on_error: retry_422_resource_not_found(3, $deployment_get_retries) do
    $deployment_get_retries = $deployment_get_retries + 1
    call sys_log("Try number "+$deployment_get_retries,{})
    # Intentionally try to get something we"ll never get
    @deployment = rs.deployments.get(id: "abc")
  end
end
