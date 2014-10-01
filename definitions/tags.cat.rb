define get_tags_for_resource(@resource) return $tags do
  $tags = []
  $tags_response = rs.tags.by_resource(resource_hrefs: [@resource.href])
  $inner_tags_ary = first(first($tags_response))['tags']
  $tags = concurrent map $current_tag in $inner_tags_ary return $tag do
    $tag = $current_tag['name']
  end
  $tags = $tags
end
