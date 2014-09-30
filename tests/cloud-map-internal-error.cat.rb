name 'cloud-map-internal-error'
rs_ca_ver 20131202
short_description 'Strange internal error when performing map on clouds'

operation 'launch' do
  description 'Do the stuff'
  definition 'launch'
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define get_clouds_by_rel($rel) return @clouds do
  @clouds = concurrent map @cloud in rs.clouds.get() return @cloud_with_rel do
    #$rels = select(@cloud.links, {'rel': $rel})
    #call log('Attempting to match '+$rel+' resulted in '+to_json($rels),'None')
    #if size($rels) > 0
      # No filtering, just return it..
      @cloud_with_rel = @cloud
    #end
  end
end

define launch() do
  call get_clouds_by_rel('volumes') retrieve @clouds_with_volume_support
end

# Results in;
# launch failed:
#
# Problem:
#   An internal error occurred
# Origin:
#   line: 10, column: 13
#     task: /root
#     expression:
#     @clouds = concurrent map @cloud in rs.clouds.get() return @cloud_with_rel do
#     |   @cloud_with_rel = @cloud
#     end
# Summary:
#   Error code: 3h30p1w7g6blj undefined method `+' for nil:NilClass
# Resolution:
#   Contact support and report error code provided in summary
