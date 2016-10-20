name "log"
rs_ca_ver 20160622
package "log"
short_description "A set of tools for logging messages"

# Creates a "log" entry in the form of an audit entry.  The target of the audit
# entry defaults to the deployment created by the CloudApp, but can be specified
# with the "auditee_href" option.
#
# @param $summary [String] the value to write in the "summary" field of an audit entry
# @param $options [Hash] a hash of options where the possible keys are;
#   * detail [String] the message to write to the "detail" field of the audit entry. Default: ""
#   * notify [String] the event notification catgory, one of (None|Notification|Security|Error).  Default: None
#   * auditee_href [String] the auditee_href (target) for the audit entry. Default: @@deployment.href
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceAuditEntries.html#create
define write($summary,$options) do
  $log_default_options = {
    detail: "",
    notify: "None",
    auditee_href: @@deployment.href
  }

  $log_merged_options = $options + $log_default_options
  rs_cm.audit_entries.create(
    notify: $log_merged_options["notify"],
    audit_entry: {
      auditee_href: $log_merged_options["auditee_href"],
      summary: $summary,
      detail: $log_merged_options["detail"]
    }
  )
end
