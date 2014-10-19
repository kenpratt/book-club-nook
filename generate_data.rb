#!/usr/bin/env ruby

require "nokogiri"
require "open-uri"
require "amazon/ecs"
require "csv"
require "json"
require "pry"
require "yaml"

$config = YAML.load_file("config.yml")

Amazon::Ecs.options = {
  :associate_tag => $config["aws"]["associate_tag"],
  :AWS_access_key_id => $config["aws"]["access_key"],
  :AWS_secret_key => $config["aws"]["secret_key"]
}

def main
  load_books
  update_data
  save_books
  generate_csv
  generate_json
  generate_js
end

def update_data
  update_list_from_vpl
  fix_missing_vpl_info
  t1 = Thread.new { fetch_goodreads_data }
  t2 = Thread.new { fetch_amazon_data }
  t1.join
  t2.join
end

def update_list_from_vpl
  puts "updating book list from vpl"
  mutex = Mutex.new
  (1..5).map do |page|
    Thread.new do
      url = "http://vpl.bibliocommons.com/search?display_quantity=100&formats=BOOK_CLUB_KIT&page=#{page}&q=book+club+kit&search_category=keyword&sort%5Bdirection%5D=ascending&sort%5Bfield%5D=TITLE&sort%5Btype%5D=BIB_FIELDS&t=catalogue&view=medium"
      doc = Nokogiri::HTML(open(url))

      doc.css("#bibList .listItem").each do |el|
        next unless el.css(".callNumber").text.strip =~ /^(YA )?BOOK CLUB SETS/

        id = el.attr("id").sub(/^bib/, "")

        book = nil
        mutex.synchronize do
          book = $books[id]
          book = $books[id] = { vpl_id: id } unless book
        end

        update_prop book, :title, get_text(el, ".title a")
        update_prop book, :vpl_url, get_attr(el, ".title a", "href")
        update_prop book, :author, get_text(el, ".author a")
        update_prop book, :availability, get_text(el, ".availability span")
        update_prop book, :availability_url, get_attr(el, ".availability a", "href")
        update_prop book, :holds, get_text(el, ".holdposition")

        rating_style = get_attr(el, ".currentRating", "style")
        update_prop book, :vpl_rating, rating_style =~ /width: ([\d\.]+)%/ ? $1.to_f : nil

        jacket_img = get_attr(el, ".jacketCoverLink img", "src")
        update_prop book, :img, jacket_img
        update_prop book, :isbn, jacket_img =~ /isbn=(\w+)/ ? $1 : nil
      end
    end
  end.each(&:join)
end

def fix_missing_vpl_info
  $books.map do |id, book|
    Thread.new do
      if !book[:vpl_rating] || !book[:description]
        puts "updating vpl data: #{book[:title]} #{!!book[:description]}"
        url = "http://vpl.bibliocommons.com" + book[:vpl_url]
        doc = Nokogiri::HTML(open(url))

        rating_style = get_attr(doc, ".currentRating", "style")
        update_prop book, :vpl_rating, rating_style =~ /width: ([\d\.]+)%/ ? $1.to_f : nil

        update_prop book, :description, get_text(doc, "#tab_content_description > div")
      end
    end
  end.each(&:join)
end

def fetch_goodreads_data
  last_request = Time.now - 2
  $books.each do |id, book|
    if book[:isbn] && (!book[:goodreads_id] || !book[:goodreads_rating] || !book[:goodreads_categories])
      puts "updating goodreads data: #{book[:title]}"
      url = nil
      begin
        elapsed = Time.now - last_request
        sleep(1 - elapsed) if elapsed < 1
        last_request = Time.now

        url = "https://www.goodreads.com/book/isbn?key=#{$config["goodreads"]["access_key"]}&format=XML&isbn=#{book[:isbn]}"
        # url = "https://www.goodreads.com/search.xml?key=#{$config["goodreads"]["access_key"]}&q=#{book[:isbn]}"
        doc = Nokogiri::XML(open(url))

        update_prop book, :goodreads_id, get_text(doc, "GoodreadsResponse > book > id")
        rating = get_text(doc, "GoodreadsResponse > book > average_rating")
        update_prop book, :goodreads_rating, rating ? rating.to_f : nil
        update_prop book, :goodreads_categories, doc.css("GoodreadsResponse > book > popular_shelves > shelf").map {|s| s.attr("name") }
      rescue => e
        puts "#{url} #{e.message}"
      end
    end
  end
end

def fetch_amazon_data
  $books.each do |id, book|
    if book[:isbn] && (!book[:amazon_url] || !book[:amazon_rating])
      puts "updating amazon data: #{book[:title]}"
      url = nil
      begin
        sleep 1
        url = "http://amazon...#{book[:isbn]}"
        res = Amazon::Ecs.item_lookup(book[:isbn], {:id_type => "ISBN", :search_index => "Books", :response_group => "Large" })
        if (items = res.doc.css("Items Item")) && !items.empty? && (el = items[0])
          update_prop book, :amazon_url, get_text(el, "DetailPageURL")

          url = get_text(el, "CustomerReviews IFrameURL")
          doc = Nokogiri::HTML(open(url))
          avg_stars = get_attr(doc, ".crAvgStars img", "title")
          update_prop book, :amazon_rating, avg_stars =~ /^([\d\.]+) out of ([\d\.]+) stars$/ ? ($1.to_f / $2.to_f) : nil
          # puts book[:amazon_rating]
        end
      rescue => e
        puts "#{url} #{e.message}"
      end
    end
  end
end

def load_books
  $books = {}
  begin
    $books = Marshal.load(open("books.db"))
  rescue Exception => e
  end
end

def save_books
  File.open("books.db", "w") {|f| f << Marshal.dump($books) }
end

def update_prop(book, key, val)
  if val.nil?
    book[key] ||= nil
  else
    book[key] = val
  end
end

def get_text(el, selector)
  match = el.css(selector)
  match.empty? ? nil : match[0].text.strip
end

def get_attr(el, selector, attr)
  match = el.css(selector)
  match.empty? ? nil : match[0].attr(attr)
end

def generate_csv
  CSV.open("books.csv", "wb") do |csv|
    keys = $books.values.first.keys
    csv << keys
    $books.each do |id, book|
      csv << keys.map {|k| book[k] }
    end
  end
end

def generate_json
  File.open("books.json", "w") {|f| f << $books.to_json }
end

def generate_js
  File.open("public/books.js", "w") do |f|
    f << "window.bookData = "
    f << $books.to_json
    f << ";\n"
  end
end

main
