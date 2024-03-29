class GigaBook
  attr_accessor :title, :author, :key
  def self.new_from_data(data)
    value = JSON.parse(data['value'])
    new_object = self.new
    new_object.key = data['group']
    new_object.title = value['title']
    new_object.author = value['author']
    new_object
  end

  def index_path
    "/read/#{self.key}"
  end

  def read_path
    "/read/#{self.key}/page/1"
  end

  def original_permalink
    "http://kindai.ndl.go.jp/info:ndljp/pid/#{self.key}"
  end
end
