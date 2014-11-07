name "tags_arent_resources"
rs_ca_ver 20131202
short_description "Tags aren't resources, they're hashes"

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

#include:../definitions/sys.cat.rb

#include:../definitions/tag.cat.rb

define launch() do
  $tags = rs.tags.by_tag(resource_type:"instances",tags: ["rs_monitoring:state=active"])
  call sys_log("Tags by tag", {detail: to_json($tags)})
  # Results in;
  # [
  #   [
  #     {
  #       "tags":[
  #
  #       ],
  #       "actions":[
  #
  #       ],
  #       "links":[
  #         {
  #           "rel":"resource",
  #           "href":"/api/clouds/2/instances/CC46Q440LS97"
  #         },
  #         {
  #           "rel":"resource",
  #           "href":"/api/clouds/2175/instances/EQD8A7OTNANSK"
  #         },
  #         {
  #           "rel":"resource",
  #           "href":"/api/clouds/2175/instances/92KCMJLA1PJ35"
  #         }
  #       ]
  #     }
  #   ]
  # ]

  call sys_log("First result in tags by tag", {detail: to_json(first(first($tags)))})
  # Results in;
  # {
  #   "tags":[
  #
  #   ],
  #   "actions":[
  #
  #   ],
  #   "links":[
  #     {
  #       "rel":"resource",
  #       "href":"/api/clouds/2175/instances/92KCMJLA1PJ35"
  #     },
  #     {
  #       "rel":"resource",
  #       "href":"/api/clouds/2/instances/CC46Q440LS97"
  #     },
  #     {
  #       "rel":"resource",
  #       "href":"/api/clouds/2175/instances/EQD8A7OTNANSK"
  #     }
  #   ]
  # }

  $first_resource_href = first(first(first($tags))["links"])["href"]
  call sys_log("HREF of first resource with tag", {detail: $first_resource_href})
  # Results in;
  # /api/clouds/2175/instances/EQD8A7OTNANSK

  $tags = rs.tags.by_resource(resource_hrefs: [$first_resource_href])
  #call log(to_json($tags),"None")
  # The logging actually breaks, for some reason but it would result in;
  # [
  #   [
  #     {
  #       "tags":[
  #         {
  #           "name":"ec2:Name=Base ServerTemplate for Linux (v13.5.5-LTS)"
  #         },
  #         {
  #           "name":"rs_login:state=restricted"
  #         },
  #         {
  #           "name":"rs_monitoring:state=active"
  #         },
  #         {
  #           "name":"server:private_ip_0=10.75.44.250"
  #         },
  #         {
  #           "name":"server:public_ip_0=54.74.49.124"
  #         },
  #         {
  #           "name":"server:uuid=04-8NAQ0MHG79V5P"
  #         }
  #       ],
  #       "actions":[
  #
  #       ],
  #       "links":[
  #         {
  #           "rel":"resource",
  #           "href":"/api/clouds/2/instances/CC46Q440LS97"
  #         }
  #       ]
  #     }
  #   ]
  # ]

  #call log(to_json(first(first($tags))["tags"]),"None")
  # This log also fails with an error that audit summary is in the wrong format;
  # [
  #   {
  #     "name":"ec2:Name=Base ServerTemplate for Linux (v13.5.5-LTS)"
  #   },
  #   {
  #     "name":"rs_login:state=restricted"
  #   },
  #   {
  #     "name":"rs_monitoring:state=active"
  #   },
  #   {
  #     "name":"server:private_ip_0=10.75.44.250"
  #   },
  #   {
  #     "name":"server:public_ip_0=54.74.49.124"
  #   },
  #   {
  #     "name":"server:uuid=04-8NAQ0MHG79V5P"
  #   }
  # ]


  $tags_ary = first(first($tags))["tags"]
  $new_tags = map $current_tag in $tags_ary return $tag do
    $tag = $current_tag["name"]
  end

  call sys_log("New Tags", {detail: to_json($new_tags)})

  call get_tags_for_resource($first_resource_href) retrieve $tags
  call sys_log("Tags by resource", {detail: to_json($tags)})
end
