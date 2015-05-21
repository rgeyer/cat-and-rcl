# $record_value, $record_ttl,
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
#
# @return $result [???] TODO: Haven't decided yet
#
# @see http://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html
define route53_change_recordsets($zone_id, $records, $options) return $response do
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
  if contains?(keys($options),["access_key","secret_key"])
    $signature["access_key"] = $options["access_key"]
    $signature["secret_key"] = $options["secret_key"]
  end

  $response = http_post(
    url: "https://route53.amazonaws.com/2013-04-01/hostedzone/"+$zone_id+"/rrset",
    body: $request_xml,
    signature: $signature
  )
end
