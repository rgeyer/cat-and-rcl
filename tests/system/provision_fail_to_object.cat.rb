#test:desired_state=running

name "provision_fail_to_object"
rs_ca_ver 20131202
short_description "When a CAT declaration is passed to provision() and provision() fails, the resulting CAT declaration doesn't cleanly convert to an object using to_object()"

#include:../../definitions/sys.cat.rb

resource "linux_base_1", type: "server" do
  name "linux"
  cloud_href "/api/clouds/1"
  instance_type "t2.small" # This causes failure
  ssh_key "default"
  security_groups "default"
  server_template "Base ServerTemplate for Linux (v13.5.5-LTS)"
end

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

define do_to_object($object) do
  $_error_behavior = "skip"
  $after_provision_obj = to_object(@provision_this)
  # This results in something I've never seen before.
  # { namespace: rs, type: servers, fields: { name: { _klass: Value, _line: 1, _col: 1, _anchor_text: ", type: nil, value: to_object is wierd yo, children: [] }, cloud_href: { _klass: Value, _line: 1, _col: 1, _anchor_text: ", type: nil, value: /api/clouds/1, children: [] }, instance_type_href: { _klass: Eval, _line: 1, _col: 1, _anchor_text: eval, name: eval, arguments: [{ _klass: Value, _line: 1, _col: 6, _anchor_text: ", type: nil, value: rs__find_cached, children: [] }, { _klass: Value, _line: 1, _col: 25, _anchor_text: ", type: nil, value: instance_types, children: [] }, { _klass: Value, _line: 1, _col: 43, _anchor_text: {, type: nil, value: null, children: [{ _klass: Pair, _line: 1, _col: 50, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 44, _anchor_text: ", type: nil, value: name, children: [] }, value: { _klass: Value, _line: 1, _col: 51, _anchor_text: ", type: nil, value: t2.small, children: [] } }, { _klass: Pair, _line: 1, _col: 75, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 63, _anchor_text: ", type: nil, value: cloud_href, children: [] }, value: { _klass: Value, _line: 1, _col: 76, _anchor_text: ", type: nil, value: /api/clouds/1, children: [] } }] }] }, ssh_key_href: { _klass: Eval, _line: 1, _col: 1, _anchor_text: eval, name: eval, arguments: [{ _klass: Value, _line: 1, _col: 6, _anchor_text: ", type: nil, value: rs__find_cached, children: [] }, { _klass: Value, _line: 1, _col: 25, _anchor_text: ", type: nil, value: ssh_keys, children: [] }, { _klass: Value, _line: 1, _col: 37, _anchor_text: {, type: nil, value: null, children: [{ _klass: Pair, _line: 1, _col: 52, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 38, _anchor_text: ", type: nil, value: resource_uid, children: [] }, value: { _klass: Value, _line: 1, _col: 53, _anchor_text: ", type: nil, value: default, children: [] } }, { _klass: Pair, _line: 1, _col: 76, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 64, _anchor_text: ", type: nil, value: cloud_href, children: [] }, value: { _klass: Value, _line: 1, _col: 77, _anchor_text: ", type: nil, value: /api/clouds/1, children: [] } }] }] }, security_group_hrefs: { _klass: Value, _line: 93, _col: 7, _anchor_text: provision (@provision_this), type: nil, value: null, children: [{ _klass: Eval, _line: 1, _col: 1, _anchor_text: eval, name: eval, arguments: [{ _klass: Value, _line: 1, _col: 6, _anchor_text: ", type: nil, value: rs__find_cached, children: [] }, { _klass: Value, _line: 1, _col: 25, _anchor_text: ", type: nil, value: security_groups, children: [] }, { _klass: Eval, _line: 1, _col: 44, _anchor_text: eval, name: eval, arguments: [{ _klass: Value, _line: 1, _col: 49, _anchor_text: ", type: nil, value: rs__add_default_network, children: [] }, { _klass: Value, _line: 1, _col: 76, _anchor_text: {, type: nil, value: null, children: [{ _klass: Pair, _line: 1, _col: 83, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 77, _anchor_text: ", type: nil, value: name, children: [] }, value: { _klass: Value, _line: 1, _col: 84, _anchor_text: ", type: nil, value: default, children: [] } }, { _klass: Pair, _line: 1, _col: 107, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 95, _anchor_text: ", type: nil, value: cloud_href, children: [] }, value: { _klass: Value, _line: 1, _col: 108, _anchor_text: ", type: nil, value: /api/clouds/1, children: [] } }] }] }] }] }, server_template_href: { _klass: Eval, _line: 1, _col: 1, _anchor_text: eval, name: eval, arguments: [{ _klass: Value, _line: 1, _col: 6, _anchor_text: ", type: nil, value: rs__find_cached, children: [] }, { _klass: Value, _line: 1, _col: 25, _anchor_text: ", type: nil, value: server_templates, children: [] }, { _klass: Value, _line: 1, _col: 45, _anchor_text: {, type: nil, value: null, children: [{ _klass: Pair, _line: 1, _col: 52, _anchor_text: :, key: { _klass: Value, _line: 1, _col: 46, _anchor_text: ", type: nil, value: name, children: [] }, value: { _klass: Value, _line: 1, _col: 53, _anchor_text: ", type: nil, value: Base ServerTemplate for Linux (v13.5.5-LTS), children: [] } }] }] }, deployment_href: { _klass: Value, _line: 1, _col: 1, _anchor_text: ", type: nil, value: /api/deployments/505313004, children: [] } }, dependencies: [] }
  call sys_log("before obj",{detail: to_s($object)})
  call sys_log("after obj",{detail: to_s($after_provision_obj)})
  if to_s($object) != to_s($after_provision_obj)
    raise "Expected the first and second conversion to object to produce the same
    output.  Instead, the first conversion produced;

    "+to_s($object)+"

    While the second converstion (after a failed provision()) produced;

    "+to_s($after_provision_obj)
  end
end

define launch(@linux_base_1) do
  @copy = @linux_base_1
  $object = to_object(@copy)
  sub on_error: do_to_object($object) do
    @provision_this = $object
    provision(@provision_this)
  end
end
