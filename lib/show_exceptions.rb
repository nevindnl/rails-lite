require 'erb'

class ShowExceptions
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      app.call(env)
    rescue => e
      render_exception(e)
      ['500', {'Content-type' => 'text/html'}, e.to_s]
    end
  end

  private

  def render_exception(e)
    response = Rack::Response.new
    response.status = 500
    response['Content-Type'] = 'text/html'

    html = File.read("lib/templates/rescue.html.erb")
    response.write(ERB.new(html).result(binding))
  end
end
