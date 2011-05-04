class Item
  include DataMapper::Resource

  property :screen_name, String, :key => true
  property :asin, String, :key => true
  property :title, String
  property :author, String
  property :creator, String
  property :manufacturer, String
  property :release_date, String
  property :read, Boolean, :default => false
  property :image_url, Text
  property :detail_page_url, Text
  property :created_at, DateTime
  property :updated_at, DateTime

  def self.search(query, read)
    all(:screen_name => query[:screen_name],
        :read => read,
        :title.like => "%#{query[:q]}%",
        :author.like => "%#{query[:author]}%")
  end
end
