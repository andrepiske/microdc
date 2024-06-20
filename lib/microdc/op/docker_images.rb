# frozen_string_literal: true

module Microdc
  class Op::DockerImages
    def initialize(platform)
      @platform = platform

      # @api = ApiCaller.new("http://127.0.0.1:3409")
      @api = ApiCaller.new("unix:///var/run/docker.sock")
    end

    def list_local_images
      @api.get_resource('/v1.41/images/json')
      # {"Containers"=>-1,
      # "Created"=>1649971694,
      # "Id"=>"sha256:9dcd8277ea4465301eadc90879486843aa8a6f00b4dd0da189c9a51c4faefe5a",
      # "Labels"=>nil,
      # "ParentId"=>"",
      # "RepoDigests"=>["webhooksuno/uno-alpha@sha256:08573c6c691d12515667060180842aa434a4180f6c6a938235f13cbb34bb74ca"],
      # "RepoTags"=>["webhooksuno/uno-alpha:a1"],
      # "SharedSize"=>-1,
      # "Size"=>238270936,
      # "VirtualSize"=>238270936}
    end

    def has_local_image?(image_name, tag)
      cmp_value = "#{registry_prefix}#{image_name}:#{tag}"

      list_local_images.any? do |img_def|
        (img_def['RepoTags'] || []).any? do |local_image|
          local_image == cmp_value
        end
      end
    end

    def pull_image(image_name, tag, force: false)
      return true unless force || !has_local_image?(image_name, tag)

      auth_info = Base64.urlsafe_encode64(MultiJson.dump({
        username: @platform[:registry_user],
        password: @platform[:registry_password],
        serveraddress: @platform[:registry_url],
      }))

      response = @api.connection.post(
        path: '/v1.41/images/create',
        headers: { "Accept" => "application/json", "X-Registry-Auth" => auth_info },
        query: {
          fromImage: "#{registry_prefix}#{image_name}:#{tag}"
        }
      )

      response.status == 200
    end

    private

    def registry_prefix
      return '' if @platform[:registry_url] == 'docker.io'

      "#{@platform[:registry_url]}/"
    end
  end
end
