class Vendor < ActiveRecord::Base
  include ImageMethods
  include Scope
  belongs_to :company
  has_and_belongs_to_many :users
  has_many :articles
  has_many :categories
  has_many :cost_centers
  has_many :customers
  has_many :groups
  has_many :images, :as => :imageable
  has_many :ingredients
  has_many :items
  has_many :options
  has_many :orders
  has_many :pages
  has_many :partials
  has_many :presentations
  has_many :quantities
  has_many :roles
  has_many :settlements
  has_many :tables
  has_many :roles
  has_many :taxes
  has_many :vendor_printers

  serialize :unused_order_numbers

  validates_presence_of :name

  accepts_nested_attributes_for :vendor_printers, :allow_destroy => true, :reject_if => proc { |attrs| attrs['name'] == '' }

  accepts_nested_attributes_for :images, :allow_destroy => true, :reject_if => :all_blank

  def image
    return self.images.first.image unless Image.count(:conditions => "imageable_id = #{self.id}") == 0 or self.images.first.nil?
    "/images/client_logo.png"
  end

  def resources
    categories = {}
    self.categories.each do |c|
      articles = {}
      c.articles.each do |a|
        quantities = {}
        a.quantities.each do |q|
          quantities.merge! q.id => { :id => q.id, :pre => q.prefix, :post => q.postfix, :p => q.price, :s => q.position }
        end
        articles.merge! a.id => { :id => a.id, :n => a.name, :p => a.price, :s => a.position, :q => quantities }
      end
      options = {}
      c.options.each do |o|
        options.merge! o.id => { :id => o.id, :n => o.name, :p => o.price }
      end
      categories.merge! c.id => { :id => c.id, :a => articles, :o => options }
    end
    resources = { :c => categories }
    return resources.to_json
  end

end
