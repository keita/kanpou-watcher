require "hpricot"
require "open-uri"
require "kconv"
require "date"

module KanpouWatcher
  class Kanpou
    attr_reader :label, :uri, :date

    # uri:: Kanpou uri
    # label:: Kanpou label name
    def initialize(uri, label)
      @label = label
      @uri = uri
      year, month, day = /(20\d{2})(\d{2})(\d{2})/.match(uri.to_s)[1..3]
      @date = Date.new(year.to_i, month.to_i, day.to_i)
    end

    # Returns Kanpou pdf uris.
    def pdf
      begin
        if /0f.html$/.match(@uri.to_s)
          uri = URI.parse(@uri.to_s.gsub("f.html", ".html"))
          list = Array.new
          (Hpricot(uri.read)/"a").each do |link|
            list << uri + "./pdf/" + link[:href].gsub("f.html", ".pdf")
          end
          return list.uniq
        else
          path = @uri.path.split("/")
          uri = @uri.clone
          uri.path = (path[0..-2] << "pdf" << path[-1].gsub("f.html", ".pdf")).join("/")
          return [uri]
        end
      rescue OpenURI::HTTPError
        p @uri
      end
    end
  end

  # Returns a list of KanpouWatcher::Kanpou objects published in this week.
  def self.week
    uri = URI.parse("http://kanpou.npb.go.jp/html/contents.html")
    list = Array.new
    (Hpricot(uri.read)/"td/p/a").each do |link|
      list << Kanpou.new(uri + link[:href], link.inner_text.toutf8)
    end
    return list
  end
end
