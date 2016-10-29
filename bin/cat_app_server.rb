require 'rack'
require_relative '../lib/controller_base.rb'
require_relative '../lib/router'
require_relative '../lib/activerecord/04_associatable2'

class Cat < SQLObject
  attr_accessor :name, :owner_id, :id, :owner, :house

  def initialize(params = {})
    params ||= {}
    @name, @owner = params["name"], params["owner"]
  end

  def house=
    @house = has_one_through :house, :owner, :house
  end
end

class Human < SQLObject
  attr_accessor :fname, :lname, :house_id, :id

  belongs_to :house,
    primary_key: :id,
    foreign_key: :house_id,
    class_name: :House

  has_many :cats,
    primary_key: :id,
    foreign_key: :owner_id,
    class_name: :Cat
end

class House < SQLObject
  attr_accessor :address, :id
end


class CatsController < ControllerBase
  protect_from_forgery

  def create
    @cat = Cat.new(params["cat"])
    if @cat.save
      flash[:notice] = "Saved cat successfully"
      redirect_to "/cats"
    else
      flash.now[:errors] = @cat.errors
      render :new
    end
  end

  def index
    @cats = Cat.all
    render :index
  end

  def new
    @cat = Cat.new
    render :new
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/cats$"), CatsController, :index
  get Regexp.new("^/cats/new$"), CatsController, :new
  get Regexp.new("^/cats/(?<id>\\d+)$"), CatsController, :show
  post Regexp.new("^/cats$"), CatsController, :create
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

Rack::Server.start(
 app: app,
 Port: 3000
)
