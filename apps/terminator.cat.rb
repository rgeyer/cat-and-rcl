name 'terminator'
rs_ca_ver 20131202
short_description 'Find old stuff, delete it.. Save money..'

parameter 'instances_hours_old_param' do
  type 'number'
  label 'Instance Age in hours'
  default 24
end

parameter 'skip_tag_param' do
  type 'string'
  label 'Tag, which if applied to a resource will instruct the terminator to spare that resource'
  default 'terminator:skip=true'
end

operation 'launch' do
  description 'Do the stuff'
  definition 'terminator'
end

# From ../definitions/sys.cat.rb
define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

# From ../definitions/sys.cat.rb
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

# From ../definitions/tags.cat.rb
define get_tags_for_resource(@resource) return $tags do
  $tags_response = rs.tags.by_resource(resource_hrefs: [@resource.href])
  $inner_tags_ary = first(first($tags_response))['tags']
  $tags = concurrent map $current_tag in $inner_tags_array return $tag do
    $tag = $current_tag['name']
  end
end

define terminator($instances_hours_old_param,$skip_tag_param) do
  concurrent do
    sub task_name:'instances' do
      concurrent foreach @cloud in rs.clouds.get() do
        concurrent foreach @instance in @cloud.instances().get() do
          $instances_hours_old_seconds = (to_n($instances_hours_old_param)*60)*60
          call get_tags_by_resource(@instance) retrieve $tags
          $created_at = @instance.created_at
          $created_delta = now() - to_n($created_at)

          # TODO: This is comparing different data types, left hand is datetime, right hand is int/number
          $is_old_enough = $created_delta > $instances_hours_old_seconds
          $is_not_tagged = logic_not(contains?($tags, $skip_tag_param))
          if $is_old_enough & $is_not_tagged
            call log('Would terminate '+@instance.name+' because it is older than '+$instance_hours_old_seconds+' seconds, and is not tagged with'+$skip_tag_param,'None')
          else
            call log('Leaving '+@instance.name+' alone because it is not older than '+$instance_hours_old_seconds+' seconds, or is not tagged with'+$skip_tag_param,'None')
          end
        end
      end
    end

    sub task_name:'volumes' do
      call get_clouds_by_rel('volumes') retrieve @clouds
    end

    sub task_name:'snapshots' do
      call get_clouds_by_rel('volume_snapshots') retrieve @clouds
    end

    sub task_name:'ips' do

    end

    sub task_name:'ssh_keys' do

    end

    # sub task_name:'server_templates' do
    #
    # end

    # sub task_name:'Services? ELB, RDS, Other stuff?' do
    #
    # end
  end
end
