# Creates a new RightScale Credential with the provided details
#
# @param $credential_name [String] The desired name of the credential.
#   I.E. DB_PASSWORD
# @param $credential_value [String] The desired value of the credential.
#   I.E. Sup3r$ecure!
# @param $credential_description [String] An optional description for the
#   credential. Provide an empty string for none.
#
# @return @credential [CredentialResourceCollection] the newly created
#   credential
define credential_create($credential_name,$credential_value,$credential_description) return @credential do
  $credential_params = {
    name => $credential_name,
    value => $credential_value
  }
  if size($credential_description) > 0
    $credential_params['description'] = $credential_description
  end
  @credential = rs.credentials.create(credential: $credential_params)
end

# Deletes a RightScale Credential identified by name. If multiple credentials
# with the same name are found, all of them will be deleted.
#
# @param $credential_name [String] The name of the credential to delete
define credential_delete($credential_name) do
  @credential = find("credentials", $credential_name)
  @credential.destroy()
end

# Updates a RightScale Credential identified by name. If multiple credentials
# with the same name are found, all of them will be updated
#
# @param $credential_name [String] The current name of the credential, used to
#   find the credential which should be updated I.E. DB_PASSWORD
# @param $update_values [Hash] a hash of values to update for the found
#   credentials. The possible keys are;
#   * name [String] The desired replacement name of the credential.
#   I.E. DB_PASSWORD
#   * value [String] The desired value of the credential. I.E. Sup3r$ecure!
#   * description [String] An optional description for the credential. Provide
#     an empty string for none.
#
# @return @credential [CredentialResourceCollection] the updated credential
define credential_update($credential_name,$update_values) return @credential do
  @credential = find("credentials", $credential_name)
  @credential.update(credential: $update_values)
end

# Fetches the value of a credential identifed by name. This is reliable since
# the system restricts you from creating duplicate credentials with the same name
#
# @param $name [String] The name of the credential for which to fetch the value
#
# @return $value [String] The value of the credential
define credential_get_value($name) return $value do
  @cred = rs.credentials.get(filter: "name=="+$name, view: "sensitive")

  if size(@cred) == 0
    raise "Unable to find credential with name: " + $name
  end
  
  $cred_object = to_object(@cred)
  $value = first($cred_object["details"])["value"]
end
