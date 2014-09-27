name 'number_param_is_not_int'
rs_ca_ver 20131202
short_description 'Parse error states that there is no implicit conversion from String to Integer.  This appears to be from the "number" quantity param being passed into an integer only field for array (min and max count on array)'

parameter 'qty_param' do
  type 'number'
  label 'Quantity'
  default 1
end

resource 'base_array_res', type: 'array' do
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
      'max_count' => $qty_param,
    },
    'pacing' => {
      'resize_calm_time' => 10,
      'resize_down_by' => 1,
      'resize_up_by' => 1,
    },
    'alert_specific_params' => {
      'decision_threshold' => 51,
      'voters_tag_predicate' => 'notdefined'
    },
  } end
end
