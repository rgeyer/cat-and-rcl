# Make changes to a Route53 recordset
#
# @param $zone_id [String] The Route53 Hosted Zone ID on which to apply the recordset changes
# @param $records [Array<Hash>] An array of hashes describing the individual changes.
#   Where each hash has the following keys;
#   * action [String] one of (CREATE|DELETE|UPSERT)
#   * type [String] the DNS record type
#   * name [String] the record name I.E. www.foo.com
#   * ttl [Int] the DNS record TTL
#   * values [Array<String>] an array of DNS record values
# @param $options [Hash] a hash of options where the possible keys are;
#   * access_key [String] an AWS_ACCESS_KEY_ID to use for authentication.
#     If not supplied the account credential cred:AWS_ACCESS_KEY_ID will be used
#   * secret_key [String] an AWS_SECRET_ACCESS_KEY to use for authentication.
#     If not supplied the account credential cred:AWS_SECRET_ACCESS_KEY will be used
#   * raise_on_error [Bool] Whether to raise an exception if an error occurs. Default: true
#   * wait_for_insync [Bool] Whether to wait for the change request to transition to the INSYNC status. Default: true
#
# @return $response [Hash] A hash representing the http_* response
#
# @see http://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html
define route53_change_recordsets($zone_id, $records, $options) return $response do
  $default_options = {
    raise_on_error: true,
    wait_for_insync: true
  }

  $merged_options = $options + $default_options

  $request_lines = []
  $comment_lines = []
  $change_lines = []
  foreach $record in $records do
    $comment_lines << "    "+$record["action"]+" a "+$record["type"]+" record for "+$record["name"]+" with values "+to_json($record["values"])+" and a TTL of "+$record["ttl"]

    $change_lines << "      <Change>"
    $change_lines << "        <Action>"+$record["action"]+"</Action>"
    $change_lines << "        <ResourceRecordSet>"
    $change_lines << "          <Name>"+$record["name"]+"</Name>"
    $change_lines << "          <Type>"+$record["type"]+"</Type>"
    $change_lines << "          <TTL>"+$record["ttl"]+"</TTL>"
    $change_lines << "          <ResourceRecords>"
    $change_lines << "            <ResourceRecord>"
    foreach $value in $record["values"] do
      $change_lines << "              <Value>"+$value+"</Value>"
    end
    $change_lines << "            </ResourceRecord>"
    $change_lines << "          </ResourceRecords>"
    $change_lines << "        </ResourceRecordSet>"
    $change_lines << "      </Change>"
  end

  $request_lines << '<?xml version="1.0" encoding="UTF-8"?>'
  $request_lines << '<ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2013-04-01/">'
  $request_lines << "  <ChangeBatch>"
  $request_lines << "    <Comment>"
  foreach $line in $comment_lines do
    $request_lines << $line
  end
  $request_lines << "    </Comment>"
  $request_lines << "    <Changes>"
  foreach $line in $change_lines do
    $request_lines << $line
  end
  $request_lines << "    </Changes>"
  $request_lines << "  </ChangeBatch>"
  $request_lines << "</ChangeResourceRecordSetsRequest>"

  $request_xml = join($request_lines, "\n")
  $signature = { type: "aws" }
  if contains?(keys($merged_options),["access_key","secret_key"])
    $signature["access_key"] = $merged_options["access_key"]
    $signature["secret_key"] = $merged_options["secret_key"]
  end

  $response = http_post(
    url: "https://route53.amazonaws.com/2013-04-01/hostedzone/"+$zone_id+"/rrset",
    body: $request_xml,
    signature: $signature
  )

  if $response["code"] != 200
    if $merged_options["raise_on_error"]
      raise "Error occurred while requesting recordset change from Route53\nRequest: "+$request_xml+"\n\nResponse: "+to_s($response["body"])
    end
  else
    if $merged_options["wait_for_insync"]
      $change_id = last(split($response["body"]["ChangeResourceRecordSetsResponse"]["ChangeInfo"]["Id"], "/"))
      sub task_name: "wait for INSYNC", timeout: 10m do
        $insync = false;
        $get_change_options = $merged_options
        $get_change_options["raise_on_error"] = false
        while $insync == false do
          call route53_get_change($change_id, $get_change_options) retrieve $change_response
          if $change_response["code"] != 200
            raise "Error occurred while requesting change status from Route53\Response: "+to_s($change_response["body"])
          else
            if $change_response["body"]["GetChangeResponse"]["ChangeInfo"]["Status"] == "INSYNC"
              $insync = true
            end
          end
          sleep(10)
        end
      end
    end
  end
end

# Get status of a change to a Route53 recordset
#
# @param $change_id [String] The Route53 change id to get
# @param $options [Hash] a hash of options where the possible keys are;
#   * access_key [String] an AWS_ACCESS_KEY_ID to use for authentication.
#     If not supplied the account credential cred:AWS_ACCESS_KEY_ID will be used
#   * secret_key [String] an AWS_SECRET_ACCESS_KEY to use for authentication.
#     If not supplied the account credential cred:AWS_SECRET_ACCESS_KEY will be used
#   * raise_on_error [Bool] Whether to raise an exception if an error occurs. Default: true
#
# @return $response [Hash] A hash representing the http_* response
#
# @see http://docs.aws.amazon.com/Route53/latest/APIReference/API_GetChange.html
define route53_get_change($change_id, $options) return $response do
  $default_options = {
    raise_on_error: true
  }

  $signature = { type: "aws" }
  if contains?(keys($merged_options),["access_key","secret_key"])
    $signature["access_key"] = $merged_options["access_key"]
    $signature["secret_key"] = $merged_options["secret_key"]
  end

  $response = http_get(
    url: "https://route53.amazonaws.com/2013-04-01/change/"+$change_id,
    signature: $signature
  )

  if $response["code"] != 200
    if $merged_options["raise_on_error"]
      raise "Error occurred while requesting change status from Route53\nChange ID: "+$change_id+"\n\nResponse: "+to_s($response["body"])
    end
  end
end
