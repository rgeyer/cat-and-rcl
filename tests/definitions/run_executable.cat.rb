name "run_executable"
rs_ca_ver 20131202
short_description "This is not an empty string"

parameter "instance_href_param" do
  type "string"
  label "Instance HREF"
  description "The proper api href for an instance"
  allowed_pattern "/api/clouds/[0-9]+/instances/[0-9a-zA-Z]+"
end

parameter "server_href_param" do
  type "string"
  label "Server HREF"
  description "The proper api href for a server"
  allowed_pattern "/api/servers/[0-9a-zA-Z]+"
end

parameter "recipe_name_param" do
  type "string"
  label "Recipe Name"
  description "The name of a chef recipe which is associated with both the instance and the server provided above"
  allowed_pattern "[a-zA-Z0-9-_]+::[a-zA-Z0-9-_]+"
end

parameter "rightscript_name_param" do
  type "string"
  label "RightScript Name"
  description "The name of a RightScript which has both a HEAD and Revision 1"
end

parameter "rightscript_href_param" do
  type "string"
  label "RightScript HREF"
  description "The proper api href for a rightscript"
  allowed_pattern "/api/right_scripts/[0-9a-zA-Z]+"
end

operation "launch" do
  description "Do the stuff"
  definition "launch"
end

#include:../../definitions/sys.cat.rb

#include:../../definitions/run_executable.cat.rb

define launch($instance_href_param,$server_href_param,$recipe_name_param,$rightscript_name_param,$rightscript_href_param) do
  @server = rs.get(href: $server_href_param)
  @instance = rs.get(href: $instance_href_param)
  @script = rs.get(href: $rightscript_href_param)
  concurrent do
    # Happy path server
    sub task_name:"server recipe" do
      $options = {
        recipe: $recipe_name_param
      }
      call run_executable(@server, $options) retrieve @tasks
    end

    sub task_name:"server script href" do
      $options = {
        rightscript: {
          href: $rightscript_href_param
        }
      }
      call run_executable(@server, $options) retrieve @tasks
    end

    sub task_name:"server script name (head revision)" do
      $options = {
        rightscript: {
          name: $rightscript_name_param
        }
      }
      call run_executable(@server, $options) retrieve @tasks
    end

    sub task_name:"server script name (revision 1)" do
      $options = {
        rightscript: {
          name: $rightscript_name_param,
          revision: 1
        }
      }
      call run_executable(@server, $options) retrieve @tasks
    end

    sub task_name:"server script name (boot revmatch)" do
      $options = {
        rightscript: {
          name: $rightscript_name_param,
          revmatch: "boot"
        }
      }
      call run_executable(@server, $options) retrieve @tasks
    end



    # Happy path instance
    sub task_name:"instance recipe" do
      $options = {
        recipe: $recipe_name_param
      }
      call run_executable(@instance, $options) retrieve @tasks
    end

    sub task_name:"instance script href" do
      $options = {
        rightscript: {
          href: $rightscript_href_param
        }
      }
      call run_executable(@instance, $options) retrieve @tasks
    end

    sub task_name:"instance script name (head revision)" do
      $options = {
        rightscript: {
          name: $rightscript_name_param
        }
      }
      call run_executable(@instance, $options) retrieve @tasks
    end

    sub task_name:"instance script name (revision 1)" do
      $options = {
        rightscript: {
          name: $rightscript_name_param,
          revision: 1
        }
      }
      call run_executable(@instance, $options) retrieve @tasks
    end


    # TODO: Test the various failure scenarios
  end
end
