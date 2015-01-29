# Creates a new RightScale Credential with the provided details
#
# @param @credential_name [String] The desired name of the credential.
#   I.E. DB_PASSWORD
# @param @credential_value [String] The desired value of the credential.
#   I.E. Sup3r$ecure!
# @param @credential_description [String] An optional description for the
#   credential. Provide an empty string for none.
#
# @return @credential [CredentialResourceCollection] the newly created
#   credential
define create_credential($credential_name,$credential_value,$credential_description) return @credential do
  $credential_params = {
    name => $credential_name,
    description =>  $credential_description,
    value => $credential_value
  }
  @credential = rs.credentials.create(credential: $credential_params)
end

# Deletes a RightScale Credential identified by name. If multiple credentials
# with the same name are found, all of them will be deleted.
#
# @param $credential_name [String] The name of the credential to delete
define delete_credential($credential_name) do
  @credential = find("credentials", $credential_name)
  @credential.destroy()
end

# Updates a RightScale Credential identified by name. If multiple credentials
# with the same name are found, all of them will be updated
#
# @param @credential_name [String] The desired name of the credential.
#   I.E. DB_PASSWORD
# @param @credential_value [String] The desired value of the credential.
#   I.E. Sup3r$ecure!
# @param @credential_description [String] An optional description for the
#   credential. Provide an empty string for none.
define update_credential($credential_name,$credential_value,$credential_description) return @credential do
  $credential_params = {
    name => $credential_name,
    description =>  $credential_description,
    value => $credential_value
  }
  @credential = find("credentials", $credential_name)
  @credential.update(credential: $credential_params)
end
