cat-and-rcl
===========

Storage bucket for misc useful RightScale SelfService things.

```
bundle install

mkdir -p ~/.right_api_client
cp login.yml.example ~/.right_api_client/login.yml

# Edit login.yml accordingly

rake -T
```

Including
=========

For any of the rake tasks that deal with templates, the template will be preprocessed
to replace any #include:/path/to/another/cat/file with the contents of that file.

This allows for shared libraries to be built and stored along side your CATs.

Example:

Main template
```
name 'cat-with-includes'
rs_ca_ver 20131202
short_description 'has some includes'

#include:../definitions/foo.cat.rb
```

foo.cat.rb
```
define foo() return @clouds do
  @clouds = rs.clouds.get()
end
```

Results in
```
name 'cat-with-includes'
rs_ca_ver 20131202
short_description 'has some includes'

###############################################################################
# BEGIN Include from ../definitions/foo.cat.rb
###############################################################################
define foo() return @clouds do
  @clouds = rs.clouds.get()
end
###############################################################################
# END Include from ../definitions/foo.cat.rb
###############################################################################
```

API Requests
============

There are rake tasks for specific API calls

cloudapp_list
--------------
List all your running CloudApps

```
rake cloudapp_list
Logging into RightScale API 1.5 @ https://us-4.rightscale.com
Logging into self service @ https://selfservice-4.rightscale.com
[
  {
    "kind": "self_service#execution",
    "id": "546e780a1aad6a37a900001c",
    "name": "foo",
    "href": "/api/manager/projects/44134/executions/546e780a1aad6a37a900001c",
    "description": "This is not an empty string",
    "status": "running",
    "cost": {
      "value": "0.00",
      "unit": "$",
      "updated_at": null
    },
    "deployment": "/api/deployments/504781004",
    "created_by": {
      "id": 42138,
      "name": "Ryan Geyer",
      "email": "ryan.geyer@rightscale.com"
    },
    "timestamps": {
      "created_at": "2014-11-20T23:23:54+00:00",
      "launched_at": "2014-11-20T23:23:54+00:00",
      "terminated_at": null
    },
    "links": {
      "running_operations": {
        "href": "/api/manager/projects/44134/operations?filter[]=execution_id==546e780a1aad6a37a900001c&filter[]=status==running"
      },
      "latest_notifications": {
        "href": "/api/manager/projects/44134/notifications?filter[]=execution_id==546e780a1aad6a37a900001c"
      }
    }
  }
]

```

template_compile
----------------
Preprocesses the CAT, then compiles it.  On success, it's pretty quiet.

```
rake "template_compile[tests/definitions/server_template_tests.cat.rb]"
Logging into RightScale API 1.5 @ https://us-4.rightscale.com
Logging into self service @ https://selfservice-4.rightscale.com
Uploading template to SS compile_template
Template compiled successfully
```

If compile fails, you'll know why.

```
rake "template_compile[tests/parsefail.cat.rb]"
Logging into RightScale API 1.5 @ https://us-4.rightscale.com
Logging into self service @ https://selfservice-4.rightscale.com
Uploading template to SS compile_template
Failed to compile template
[
  {
    "origin": "template: template.cat, line: 236",
    "problem": "Undefined variable or method",
    "summary": "'error' is undefined",
    "resolution": "Review the list of built-in methods at http://support.rightscale.com"
  },
  {
    "origin": "template: template.cat, line: 0",
    "problem": "Missing short description",
    "summary": "Template source is missing 'short_description' declaration",
    "resolution": "Please add a 'short_description' declaration, e.g. short_description \"My CloudApp\""
  },
  {
    "origin": "template: template.cat, line: 0",
    "problem": "Missing engine version",
    "summary": "Template source is missing 'rs_ca_ver' declaration",
    "resolution": "Please add a 'rs_ca_ver' declaration, e.g. rs_ca_ver \"20121202\""
  }
]
```

template_list
-------------
Lists all the available templates, no options, though some would likely be useful

```
rake template_list                                                                    *[master][ruby-1.9.3-p545@cat-and-rcl]
Logging into RightScale API 1.5 @ https://us-4.rightscale.com
Logging into self service @ https://selfservice-4.rightscale.com
[
  {
    "kind": "self_service#template",
    "id": "546e77cea20be70e1e00007e",
    "name": "server_template_tests",
    "filename": "server_template_tests20141120-41959-1gwp7xc.cat.rb",
    "href": "/api/designer/collections/44134/templates/546e77cea20be70e1e00007e",
    "short_description": "This is not an empty string",
    "created_by": {
      "id": 42138,
      "name": "Ryan Geyer",
      "email": "ryan.geyer@rightscale.com"
    },
    "timestamps": {
      "created_at": "2014-11-20T23:22:54+00:00",
      "updated_at": "2014-11-20T23:22:54+00:00",
      "published_at": null
    }
  }
]
```

template_upsert
---------------
Creates or updates a template based on the CAT name, just like the UI

```
rake "template_upsert[tests/definitions/server_template_tests.cat.rb]"
Logging into RightScale API 1.5 @ https://us-4.rightscale.com
Logging into self service @ https://selfservice-4.rightscale.com
Template upserted. HREF: /api/designer/collections/44134/templates/546e77cea20be70e1e00007e
```

#Tests

You can run tests with the "test" rake task.

```
rake test
```

By default the test task runs all tests found in tests/\*\*/\*.cat.rb, but you
can specify your own glob (relative to tests/)

```
rake "test[system/*.cat.rb]"
```

## Test types

There are three types of tests you can run.

### Compile Only

If you have a CAT you expect to compile successfully you can use the tag
test:compile_only=true

```
#test:compile_only=true

name "UTF-8 Test"
rs_ca_ver 20131202
short_description "Caché"

parameter "foo" do
  type "string"
  label "Foo"
  default "Caché"
  operations "launch"
end
```

If you expect it to compile successfully but it doesn't due to system issues you'd
use the test:desired_state=running tag.

```
#test:compile_only=true
#test:desired_state=running

name "UTF-8 Test"
rs_ca_ver 20131202
short_description "Caché"

parameter "foo" do
  type "string"
  label "Foo"
  default "Caché"
  operations "launch"
end
```

If you expect it to fail to compile, you'd use the test:expected_state=failed
tag.

```
#test:compile_only=true
#test:expected_state=failed

name "UTF-8 Test"
rs_ca_ver 20131202
short_description "Caché"

parameter "foo" do
end

# Should fail to compile because parameter "foo" has no parameters
```

### CloudApp Executes

If you expect a CloudApp to execute successfully, you don't need to specify anything
at all.

```
name "foo"
rs_ca_ver 20131202
short_description "empty, but successful"
```

If you expect a CloudApp to execute successfully, or fail, it doesn't reach that
state due to a system issue, you want to specify the
test:desired_state=(running|failed) tag.

```
#test:desired_state=running

name "foo"
rs_ca_ver 20131202
short_description "foo"

operation "launch" do
  description "Test arithmetic"
  definition "launch"
end

define launch() do
  $result = 1 + 1
  if $result != 2
    raise "RCL Can't do math"
  end
end
```

If you expect a CloudApp to execute and fail, you'll want to specify the
test:expected_state=failed tag.

```
#test:expected_state=failed

name "foo"
rs_ca_ver 20131202
short_description "foo"

operation "launch" do
  description "Raise an error, failing the cloud app"
  definition "launch"
end

define launch() do
  raise "This oughta do it."
end
```

### Special Operations Execute

You can also create a single CAT with many special operations which will act as
test cases.

```
#test_operation:success_one=completed
#test_operation:success_two=completed
#test_operation:fail_one=failed

name "op tests"
rs_ca_ver 20131202
short_description "This is not an empty string"

operation "success_one" do
  description "Not empty"
  definition "success_one"
end

operation "success_two" do
  description "Not empty"
  definition "success_two"
end

operation "fail_one" do
  description "Not empty"
  definition "fail_one"
end

define success_one() do
end

define success_two() do
end

define fail_one() do
  raise "Fail"
end
```

## Results
Green - Test completed successfully and with the expected result
Yellow - Test completed successfully but did not have the tag:desired_state
Blue - Test completed successfully and did have the tag:desired_state
Red - Test did not complete successfully, or the tag:expected_state was not matched

![Results Image](readme_images/results.png)

## Test Tags
Simple tagging to identify what to test, and what the desired result is.

### test:compile_only=true
This tag indicates that simply being able to "compile" this test file represents
success.

### test:expected_state=(failed|running)
Cause sometimes it's easier to let the test "fail" or throw an exception than
to create the logic to allow it to finish.

### test:desired_state=(failed|running)
This tag implies that under normal circumstances the test would complete with the
specified state.  However, it's expected that the test won't complete with
that state due to system bugs or other things.

When a test with this tag completes in a state other than the specified state
it will be marked Yellow.

When a test with this tag completes in the specified state it will be marked Green

### test_operation:<operation name>=(completed|failed)
You might wanna have a single CAT with multiple test cases.  If so, create the CAT
and create one special operation for each test case.  Use this tag to specify
the operation name to run, and the expected outcome.
