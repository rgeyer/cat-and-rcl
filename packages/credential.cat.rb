name "Credential"
rs_ca_ver 20160622
package "credential"
short_description "A set of helper functions for interacting with RightScale credentials. (Maybe deprecated eventually as the rs_cm namespace evolves)"


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
define create($credential_name,$credential_value,$credential_description) return @credential do
  $credential_params = {
    name => $credential_name,
    value => $credential_value
  }
  if size($credential_description) > 0
    $credential_params['description'] = $credential_description
  end
  @credential = rs_cm.credentials.create(credential: $credential_params)
end

# Deletes a RightScale Credential identified by name. If multiple credentials
# with the same name are found, all of them will be deleted.
#
# @param $credential_name [String] The name of the credential to delete
define delete($credential_name) do
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
define update($credential_name,$update_values) return @credential do
  @credential = find("credentials", $credential_name)
  @credential.update(credential: $update_values)
end
