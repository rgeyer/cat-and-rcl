name "validation"
rs_ca_ver 20160622
package "validation"
short_description "A set of helper functions for validating user inputs and raising exceptions."
import "exception"

define resource_collection_size(@resource, $desired_size, $origin) do
  if size(@resource) != $desired_size
    $message = "Resource collection size, expected "+$desired_size+" items but got "+size(@resource)
    call exception.invalidArgument($origin, $message)
  end
end

define resource_collection_type(@resource, $type, $origin) do
  $type = to_s(@resource)
  if !($type =~ $type)
    $message = "Resource collection type, expected rs_cm.instances "+$type+" but got "+$type
    call exception.invalidArgument($origin, $message)
  end
end
