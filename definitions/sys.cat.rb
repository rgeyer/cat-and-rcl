define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define get_clouds_by_rel($rel) return @clouds do
  @clouds = concurrent map @cloud in rs.clouds.get() return @cloud_with_rel do
    $rels = select(@cloud.links, {'rel': $rel})
    if size($rels) > 0
      call log(@cloud.name+' supports '+$rel,'None')
      @cloud_with_rel = @cloud
    else
      call log(@cloud.name+' does not support '+$rel,'None')
    end
  end
end
