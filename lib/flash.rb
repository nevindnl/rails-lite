require 'json'

class Flash
  attr_accessor :now_cookies
  def initialize(req)
    @cookie = req.cookies['_rails_lite_app_flash']
    @cookie = @cookie.nil? ? {} : JSON.parse(@cookie)
    @now_cookies = {}
  end

  def [](key)
    @cookie[key] || @now_cookies[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    res.set_cookie('_rails_lite_app_flash', path: '/', value: @cookie.to_json)
  end

  def now
    @now_cookies
  end
end
