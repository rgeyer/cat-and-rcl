name 'quantity'
rs_ca_ver 20131202
short_description 'Launch a specified number of servers from Base ST'

parameter 'qty_param' do
  type 'number'
  label 'Quantity'
  default 1
end

parameter 'method_param' do
  type 'string'
  label 'Method'
  allowed_values 'array','clone'
end

resource 'base_server_res', type: 'server' do
  name 'Base Linux'
  cloud_href '/api/clouds/1'
  ssh_key find(resource_uid: 'default')
  security_groups find(name: 'default')
  server_template find('Base ServerTemplate for Linux (RSB) (v13.5.5-LTS)', revision: 17)
end

resource 'base_array_res', type: 'server_array' do
  name 'Base Linux'
  cloud_href '/api/clouds/1'
  ssh_key find(resource_uid: 'default')
  security_groups find(name: 'default')
  server_template find('Base ServerTemplate for Linux (RSB) (v13.5.5-LTS)', revision: 17)
  state 'disabled'
  array_type 'alert'
  elasticity_params do {
    'bounds' => {
      'min_count' => $qty_param,
      'max_count' => $qty_param
    },
    'pacing' => {
      'resize_calm_time' => 10,
      'resize_down_by' => 1,
      'resize_up_by' => 1
    },
    'alert_specific_params' => {
      'decision_threshold' => 51,
      'voters_tag_predicate' => 'notdefined'
    }
  } end
end

operation 'launch' do
  description 'launch'
  definition 'launch'
end

define log($message, $notify) do
  rs.audit_entries.create(notify: $notify, audit_entry: {auditee_href: @@deployment.href, summary: $message})
end

define launch(@base_server_res,@base_array_res,$qty_param,$method_param) return @base_server_res,@base_array_res do
  if $method_param == 'array'
    provision(@base_array_res)
  elsif $method_param == 'clone'
    $qty = 1
    $qty_ary = []
    while $qty <= to_n($qty_param) do
      $qty_ary << $qty
      $qty = $qty + 1
    end

    concurrent foreach $qty in $qty_ary do
      provision(@base_server_res)
    end
  end
end
