#!/usr/bin/env ruby
require 'net/http'
require 'cgi'
require 'json'
require 'rubygems'
require 'curb'
require 'sling/users'
require 'sling/sites'

class Hash

  def dump
    return keys.collect{|k| "#{k} => #{self[k]}"}.join(", ")
  end

end

class WrappedCurlResponse

  def initialize(response)
    @response = response
  end

  def code
    return @response.response_code
  end
  
  def message
    return @response.response_code
  end

  def body
    return @response.body_str
  end

end

module SlingInterface

  class Sling

    attr_accessor :debug

    def initialize(server="http://localhost:8080/", debug=false)
      @server = server
      @debug = debug
      @user = SlingUsers::User.admin_user()
    end

    def dump_response(response)
      puts "Response: #{response.code} #{response.message}"
      puts "#{response.body}" if @debug
    end

    def switch_user(user)
      puts "Switched user to #{user}"
      @user = user
    end

    def execute_file_post(path, fieldname, filepath, content_type)
      post_data = Curl::PostField.file(fieldname, filepath)
      post_data.content_type = content_type
      c = Curl::Easy.new(path)
      c.multipart_form_post = true
      @user.do_curl_auth(c)
      c.http_auth_types = Curl::CURLAUTH_BASIC
      c.http_post(post_data)
      res = WrappedCurlResponse.new(c)
      dump_response(res)
      return res
    end

    def execute_post(path, post_params)
      puts "URL: #{path} params: #{post_params.dump}" if @debug
      uri = URI.parse(path)
      req = Net::HTTP::Post.new(uri.path)
      @user.do_request_auth(req)
      req.set_form_data(post_params)
      res = Net::HTTP.new(uri.host, uri.port).start{ |http| http.request(req) }
      dump_response(res)
      return res
    end

    def execute_get(path)
      puts "URL: #{path}" if @debug
      uri = URI.parse(path)
      path = uri.path
      path = path + "?" + uri.query if uri.query
      req = Net::HTTP::Get.new(path)
      @user.do_request_auth(req)
      res = Net::HTTP.new(uri.host, uri.port).start { |http| http.request(req) }
      dump_response(res)
      return res
    end

    def execute_get_with_follow(url)
      found = false
      uri = URI.parse(url)
      until found
        host, port = uri.host, uri.port if uri.host && uri.port
        req = Net::HTTP::Get.new(uri.path)
        @user.do_request_auth(req)
        res = Net::HTTP.start(host, port) {|http|  http.request(req) }
        if res.header['location']
          puts "Got Redirect: #{res.header['location']}"
          uri = URI.parse(res.header['location']) 
        else
          found = true
        end
      end 
      dump_response(res)
      return res
    end

    def url_for(path)
      return "#{@server}#{path}"
    end

    def update_properties(principal, props)
      principal.update_properties(self, props)
    end

    def delete_node(path)
      result = execute_post("#{@server}#{path}", ":operation" => "delete")
    end
    
    def create_file_node(path, fieldname, filename, content_type="text/plain")
      result = execute_file_post("#{@server}#{path}", fieldname, filename, content_type)
    end

    def create_node(path, params)
      result = execute_post("#{@server}#{path}", params.update("jcr:createdBy" => @user.name))
    end

    def get_node_props_json(path)
      return execute_get("#{@server}#{path}.json").body
    end

    def get_node_props(path)
      return JSON.parse(get_node_props_json(path))
    end

    def get_node_acl_json(path)
      return execute_get("#{@server}#{path}.acl.json").body
    end

    def get_node_acl(path)
      return JSON.parse(get_node_acl_json(path))
    end

    def create_site(path)
      nodepath = "#{@server}#{path}"
      if (!(nodepath =~ /\/$/))
        nodepath = "#{nodepath}/"
      end
      result = execute_post("#{nodepath}.createsite.html", Hash.new)
    end

    def set_node_acl_entries(path, principal, privs)
      puts "Setting node acl for: #{principal} to #{privs.dump}"
      res = execute_post("#{@server}#{path}.modifyAce.html", 
                { "principalId" => principal.name }.update(
                    privs.keys.inject(Hash.new) do |n,k| 
                      n.update("privilege@#{k}" => privs[k])
                    end))
      return res
    end

    def delete_node_acl_entries(path, principal)
      res = execute_post("#{@server}#{path}.deleteAce.html", {
              ":applyTo" => principal
              })
    end

    def clear_acl(path)
      acl = JSON.parse(get_node_acl_json(path))
      acl.keys.each { |p| delete_node_acl_entries(path, p) }
    end

  end

end

if __FILE__ == $0
  puts "Sling test"  
  s = SlingInterface::Sling.new("http://localhost:8080/", false)
  um = SlingUsers::UserManager.new(s)
  um.create_group(10)
  user = um.create_test_user(10)
  s.create_node("fish", { "foo" => "bar", "baz" => "jim" })
  puts s.get_node_props_json("fish")
  puts s.get_node_acl_json("fish")

  s.set_node_acl_entries("fish", user, { "jcr:write" => "granted" })
  puts s.get_node_acl_json("fish")
end
