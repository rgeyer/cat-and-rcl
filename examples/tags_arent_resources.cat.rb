name 'tags_arent_resources'
rs_ca_ver 20131202
short_description "Tags aren't resources, they're hashes"

operation 'launch' do
  description 'Do the stuff'
  definition 'launch'
end

# From ../definitions/tags.cat.rb
define get_tags_for_resource(@resource) return $tags do
  $tags_response = rs.tags.by_resource(resource_hrefs: [@resource.href])
  $inner_tags_ary = first(first($tags_response))['tags']
  $tags = concurrent map $current_tag in $inner_tags_array return $tag do
    $tag = $current_tag['name']
  end
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define launch() do
  $tags = rs.tags.by_tag(resource_type:'instances',tags: ['rs_monitoring:state=active'])
  call log(to_json($tags),'None')
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

  call log(to_json(first(first($tags))),'None')
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

  $first_resource_href = first(first(first($tags))['links'])['href']
  call log($first_resource_href,'None')
  # Results in;
  # /api/clouds/2175/instances/EQD8A7OTNANSK

  $tags = rs.tags.by_resource(resource_hrefs: [$first_resource_href])
  #call log(to_json($tags),'None')
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

  #call log(to_json(first(first($tags))['tags']),'None')
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


  $tags_ary = first(first($tags))['tags']
  $new_tags = concurrent map $current_tag in $tags_ary return $tag do
    $tag = $current_tag['name']
  end

  call log(to_json($new_tags),'None')
end
