name "Resource"
rs_ca_ver 20160622
package "resource"
short_description "A set of helper functions for interacting with RightScale resources."
import "validation"

# Checks if a given resource has a value in the .links array with a "rel" key
# matching the value provided.
#
# @param @resource [ResourceCollection] A resource collection containing only one
#   item to search for the specified relationship
#
# @param $relname [String] The name of the relationship to check
#
# @raise exception.invalidArgument() if the @resource parameter is a resource collection with more than one item in it.
define has_relationship(@resource, $relname) return $bool do
  call validation.resource_collection_size(@resource, 1, "resource.has_relationship()")
  $link = select(@resource.links, {"rel": $relname})
  $bool = size($link) > 0
end
