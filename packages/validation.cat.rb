name "validation"
rs_ca_ver 20160622
package "validation"
short_description "A set of helper functions for validating user inputs and raising exceptions."
import "exception"

# Validates that a resource collection contains precisely the number of items
# specified.
#
# @param @resource [ResourceCollection] the resource collection to validate
# @param $desired_size [Int] the expected number of resources in the collection
# @param $origin [String] the name of the package and function asking for
#   validation. Used in the raised exception.
#
# @raise exception.invalidArgument() when the resource collection does not
#   contain the desired number of resources.
define resource_collection_size(@resource, $desired_size, $origin) do
  if size(@resource) != $desired_size
    $message = "Resource collection size, expected "+$desired_size+" items but got "+size(@resource)
    call exception.invalidArgument($origin, $message)
  end
end

# Validates that a resource collection contains the correct type of resource
#
# @param @resource [ResourceCollection] the resource collection to validate
# @param $desired_type [String] the expected type of resources in the collection
# @param $origin [String] the name of the package and function asking for
#   validation. Used in the raised exception.
#
# @raise exception.invalidArgument() when the resource collection does not
#   contain the desired type of resources.
define resource_collection_type(@resource, $desired_type, $origin) do
  $type = to_s(@resource)
  if !($type =~ $desired_type)
    $message = "Resource collection type, expected rs_cm.instances "+$desired_type+" but got "+$type
    call exception.invalidArgument($origin, $message)
  end
end
