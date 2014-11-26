name "terminator"
rs_ca_ver 20131202
short_description "Find old stuff, delete it.. Save money.."

parameter "instances_hours_old_param" do
  type "number"
  label "Instance Age in hours"
  default 24
end

parameter "volumes_hours_old_param" do
  type "number"
  label "Volume Age in hours"
  default 24
end

parameter "skip_tag_param" do
  type "string"
  label "Tag, which if applied to a resource will instruct the terminator to spare that resource"
  default "terminator:skip=true"
end

operation "everything" do
  description "Terminate Everything"
  definition "terminator"
end

operation "instances" do
  description "Terminate Instances"
  definition "instances"
end

operation "volumes" do
  description "Terminate Volumes"
  definition "volumes"
end

output "volume_timers" do
  label "Volume"
  category "Timers"
end

#include:../definitions/sys.cat.rb

#include:../definitions/tag.cat.rb

define instances($instances_hours_old_param,$skip_tag_param) do
  sub task_name:"instances" do
    concurrent foreach @cloud in rs.clouds.get() do
      concurrent foreach @instance in @cloud.instances(filter: ["state<>inactive","state<>terminated"]) do
        $instances_hours_old_seconds = (to_n($instances_hours_old_param)*60)*60
        call get_tags_for_resource(@instance) retrieve $tags
        if type($tags) == "null"
          $tags = []
        end
        $created_at = to_n(@instance.created_at)
        $created_delta = to_n(now()) - $created_at

        $is_old_enough = $created_delta > $instances_hours_old_seconds
        $is_not_tagged = logic_not(contains?($tags, [$skip_tag_param]))
        if $is_old_enough & $is_not_tagged
          call sys_log("Would terminate "+@instance.name+" because it is older than "+$instances_hours_old_seconds+" seconds, and is not tagged with "+$skip_tag_param,{})
        else
          call sys_log("Leaving "+@instance.name+" alone because it is not older than "+$instances_hours_old_seconds+" seconds, or is tagged with "+$skip_tag_param,{})
        end
      end
    end
  end
end

define volumes($volumes_hours_old_param,$skip_tag_param) do
  sub task_name:"volumes" do
    $ts = now()
    call sys_get_clouds_by_rel("volumes") retrieve @clouds
    call sys_log("Clouds with volume support is "+size(@clouds),{})
    $delta = to_n(now() - $ts)
    call sys_log("Time to find clouds with volume support - "+$delta,{})
    @volumes = concurrent map @cloud in @clouds return @cloud_volume do
      @cloud_volume = rs.volumes.empty()
      @cloud_volume = concurrent map @volume in @cloud.volumes() return @inner_volume do
        $ts = now()
        # Filter by attachment first
        $attachment = select(@volume.links, {"rel": "current_volume_attachment"})
        $delta = to_n(now() - $ts)
        $ts = now()
        call sys_log(task_name()+": Time to use select on a single volume - "+$delta,{})
        if size($attachment) == 0
          call sys_log(@volume.name+" was unattached",{})
          @inner_volume = @volume
        else
          @inner_volume = rs.volumes.empty()
        end
      end
    end
    call sys_log("There are "+size(@volumes)+" unattached volumes",{})
  end
end

define terminator($instances_hours_old_param,$volumes_hours_old_param,$skip_tag_param) do
  concurrent do
    call instances($instances_hours_old_param,$skip_tag_param)

    call volumes($volumes_hours_old_param,$skip_tag_param)

    sub task_name:"snapshots" do
      #call get_clouds_by_rel("volume_snapshots") retrieve @clouds
    end

    sub task_name:"ips" do

    end

    sub task_name:"ssh_keys" do

    end

    # sub task_name:"server_templates" do
    #
    # end

    # sub task_name:"Services? ELB, RDS, Other stuff?" do
    #
    # end
  end
end
