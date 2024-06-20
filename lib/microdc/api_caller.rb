# frozen_string_literal: true

class Microdc::ApiCaller
  class ApiCallerError < StandardError
  end
  class BadStatusCodeError < ApiCallerError
  end

  def initialize(base_url, auth: nil)
    @base_url = base_url
    @auth = auth
  end

  def get_resource(path, expect: (200..299))
    expect = [expect] if expect.is_a?(Integer)

    response = connection.get(path: path)

    if expect.include?(response.status)
      MultiJson.load(response.body)
    else
      raise BadStatusCodeError.new("Bad status #{response.status}, expecting #{expect.inspect}")
    end
  end

  def post_resource(path, payload, method: :post, expect: (200..299))
  end

  def connection
    @conn ||= begin
      headers = {
        "Accept" => "application/json",
        "User-Agent" => "minidc"
      }

      if @auth
        headers["Authorization"] = auth_header
      end

      unix_socket = nil
      base_url = @base_url

      if base_url.start_with?("unix://")
        unix_socket = base_url[7..-1]
        base_url = 'unix:///'
      elsif !base_url.start_with?("https://") && !base_url.start_with?("http://")
        base_url = "https://#{base_url}"
      end

      Excon.new(base_url, headers: headers, socket: unix_socket)
    end
  end

  private

  def auth_header
    if @auth.key?(:user) || @auth.key?(:password)
      user = @auth[:user] || ''
      password = @auth[:password] || ''
      token = Base64.strict_encode64("#{user}:#{password}")

      "Basic #{token}"
    elsif @auth.key?(:token)
      token = @auth[:token]

      "Bearer #{token}"
    else
      raise "Invalid auth param"
    end
  end
end
