# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'kindai'
require 'json'
require 'cache'
require 'gigabook'

# module Kindai::Util
#   def self.fetch_uri(uri, rich = false)
#     warn 'overrided fetch_uri'
#     Cache.get_or_set("uri:#{uri}", 3600) {
#       open(uri).read
#     }
#   end

# end

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
      Cache.get_or_set("uri:#{uri}", 3600) {
        open(uri).read
      }
    end

    def get_books
      uri = 'http://gigaschema.appspot.com/hitode909/kindai.json'
      JSON.parse(cached_content(uri))['data'].map{ |data|
        GigaBook.new_from_data(data)
      }
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
        :x      => trimming.x.to_i,
        :y      => trimming.y.to_i,
        :width  => trimming.width.to_i,
        :height => trimming.height.to_i,
      }

      book.trimming = trimming_hash
      book

    end

  end

  get '/' do
    @books = get_books
    erb :index
  end

  get '/read/:book_id' do
    @book = prepare_book(params[:book_id])

    erb :book
  end

  get '/read/:book_id/page/:page_id' do
    @book_id = params[:book_id]
    @page = params[:page_id].to_i

    erb :page
  end

  get '/read/:book_id/image/:page_id.jpg' do
    @book = prepare_book(params[:book_id])

    # set_trimming(@book)

    if params[:width] or params[:height]
      @book.trimming[:resize_w] = params[:width].to_i
      @book.trimming[:resize_h] = params[:height].to_i
    else
      @book.trimming[:resize_w] = 1440
      @book.trimming[:resize_h] = 960
    end

    redirect @book.spreads[params[:page_id].to_i].image_uri
  end


end
