class Static
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    response = Rack::Response.new
    obj = nil

    begin
      obj = File.read("lib#{env['PATH_INFO']}")
    rescue
      response.status = 404
    end

    response['Content-type'] = 'multipart/mixed'
    response.write(obj)
    response
  end
end
