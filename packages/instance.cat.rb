name "Instance"
rs_ca_ver 20160622
package "instance"
short_description "A set of helper functions for interacting with RightScale instances."
import "exception"
import "validation"

# Does some validation and gets the server template for an instance
#
# @param @instance [InstanceResourceCollection] the instance for which to get
#   the server template
#
# @return [ServerTemplateReourceCollection] The server template for the @instance
#
# @raise exception.invalidArgument() if the @instance parameter is not an instance
#   collection
# @raise exception.invalidArgument() if the @instance parameter contains more than
#   one resource
# @raise exception.invalidArgument() if the @instance does not have a server_template
#   rel
define get_server_template(@instance) return @server_template do
  call validation.resource_collection_type(@instance, "instance", "instance.get_server_template()")
  call validation.resource_collection_size(@instance, 1, "instance.get_server_template()")
  $stref = select(@instance.links, {"rel": "server_template"})
  if size($stref) == 0
    $message = "Instance does not have a server_template relationship."
    call exception.invalidArgument("instance.get_server_template()", $message)
  end
  @server_template = @instance.server_template()
end
