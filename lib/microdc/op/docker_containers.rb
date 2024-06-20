# frozen_string_literal: true

module Microdc
  class Op::DockerContainers
    def initialize(platform, app, all_containers: false)
      @platform = platform
      @app = app
      @all_containers = all_containers
      @api = ApiCaller.new("unix:///var/run/docker.sock")
    end

    def start_container(docker_id)
      r = @api.connection.post(path: "/v1.41/containers/#{docker_id}/start",
        headers: { "Accept" => "application/json" })

      r.status == 204 || r.status == 304
    end

    def list_containers
      @api.get_resource("/v1.41/containers/json?all=#{@all_containers}").select(&method(:managed_container?))
    end

    def find_by_docker_id(docker_id)
      list_containers.find do |cn|
        cn['Id'] == docker_id
      end
    end

    def stop_container(docker_id)
      r = @api.connection.post(path: "/v1.41/containers/#{docker_id}/stop",
        headers: { "Accept" => "application/json" })

      r.status == 204 || r.status == 304
    end

    def remove_container(docker_id)
      r = @api.connection.delete(path: "/v1.41/containers/#{docker_id}",
        headers: { "Accept" => "application/json" })

      r.status == 204
    end

    def wait_for_container(docker_id, timeout:)
      time_started = Time.now.to_i

      while Time.now.to_i - time_started < timeout
        container = find_by_docker_id(docker_id)
        return container if container != nil

        sleep(0.5)
      end

      nil
    end

    private

    def managed_container?(container)
      (container['Labels'] || {})["io.minidc.managed"] == "true"
    end
  end
end
