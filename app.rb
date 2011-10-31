# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'kindai'
require 'json'
require 'cache'
require 'gigabook'

module Kindai::Util
  class << self
    alias_method :fetch_uri_without_cache, :fetch_uri
    def fetch_uri(uri, rich = false)
      warn "overrided fetch_uri #{uri}"
      Cache.get_or_set("uri:#{uri}", 3600) {
        self.fetch_uri_without_cache(uri, rich)
      }
    end

    alias_method :get_redirected_uri_without_cache, :get_redirected_uri
    def get_redirected_uri(uri)
      warn "overrided get_redirected_uri #{uri}"
      Cache.get_or_set("redirected_uri:#{uri}", 3600) {
        self.get_redirected_uri_without_cache(uri)
      }
    end
  end
end

class ReaderApp < Sinatra::Base

  helpers do

    alias_method :h, :escape_html

    def stopwatch(title, &block)
      from = Time.now
      res = yield block
      warn "#{title}\t#{Time.now - from}"
      res
    end

    def cached_content(uri)
      warn "cached_content #{uri}"
      Cache.get_or_set("uri:#{uri}", 3600) {
        open(uri).read
      }
    end

    def get_books
      books = []
      (1..10).each{ |page|
        uri = "http://gigaschema.appspot.com/hitode909/kindai.json?page=#{page}"
        res = JSON.parse(cached_content(uri))
        res['data'].each{ |data|
          begin
            books << GigaBook.new_from_data(data)
          rescue JSON::ParserError
          end
        }
        break unless res['has_next']
      }
      books
    end

    def prepare_book(book_id)
      permalink = "http://kindai.ndl.go.jp/info:ndljp/pid/#{book_id}"
      book = Kindai::Book.new_from_permalink(permalink)

    end

    def set_trimming(book)
      trimming = Kindai::Util::Database.item_for_book(book)
      unless trimming
        status 404
        return "trimming info not found"
      end

      trimming_hash = {
        :x      => trimming[:x].to_i,
        :y      => trimming[:y].to_i,
        :w      => trimming[:width].to_i,
        :h      => trimming[:height].to_i,
      }

      book.trimming = trimming_hash
      book

    end

  end

  get '/' do
    @books = get_books
    erb :index
  end

  get '/read/:book_id/page/:page_id' do
    @book_id = params[:book_id]
    @page = params[:page_id].to_i

    @book = prepare_book(params[:book_id])

    erb :page
  end

  get '/setting' do
    @width = request.cookies["width"].to_i
    unless @width and @width > 0
      @width = 1440
    end
    erb :setting
  end

  get '/read.touch' do
    erb :read_touch
  end

  post '/setting' do
    width = 1440
    begin
      width = params[:width].to_i
    end

    width = 1440 if width < 0

    response.set_cookie("width", width)
    @width = width

    erb :setting
  end

  get '/read/:book_id/image/:page_id.jpg' do
    @book = prepare_book(params[:book_id])

    set_trimming(@book)

    resize_width = 1440
    resize_height = nil

    if params[:width]
      resize_width = params[:width].to_i
    elsif request.cookies["width"]
      resize_width = request.cookies["width"].to_i
    end

    if params[:width] and params[:height]
      resize_height = params[:height].to_i
    end

    resize_width = 1440 if resize_width < 0

    @book.trimming[:resize_w] = resize_width
    @book.trimming[:resize_h] = resize_height || (@book.trimming[:resize_w] * @book.trimming[:h] / @book.trimming[:w]).to_i

    page_id = 1
    begin
      page_id = params[:page_id].to_i
    end

    if page_id < 1
      page_id = 1
    end

    redirect @book.spreads[page_id - 1].image_uri
  end

  get '/read/:book_id/image/l/:page_id.jpg' do
    @book = prepare_book(params[:book_id])

    set_trimming(@book)

    resize_width = params[:width] ? params[:width].to_i : 640
    resize_height = params[:height] ? params[:height].to_i : 960

    @book.trimming[:w] = (@book.trimming[:h] * resize_width / resize_height).to_i

    @book.trimming[:resize_w] = resize_width
    @book.trimming[:resize_h] = resize_height

    page_id = 1
    begin
      page_id = params[:page_id].to_i
    end

    if page_id < 1
      page_id = 1
    end

    redirect @book.spreads[pag_id - 1].image_uri
  end

  get '/read/:book_id/image/r/:page_id.jpg' do
    @book = prepare_book(params[:book_id])

    set_trimming(@book)

    resize_width = params[:width] ? params[:width].to_i : 640
    resize_height = params[:height] ? params[:height].to_i : 960

    @book.trimming[:resize_w] = resize_width
    @book.trimming[:resize_h] = resize_height

    @book.trimming[:x] = (@book.trimming[:x] + @book.trimming[:w] - @book.trimming[:h] * resize_width / resize_height).to_i
    @book.trimming[:w] = (@book.trimming[:h] * resize_width / resize_height).to_i

    page_id = 1
    begin
      page_id = params[:page_id].to_i
    end

    if page_id < 1
      page_id = 1
    end

    redirect @book.spreads[pag_id - 1].image_uri
  end


end
