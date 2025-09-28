module Lapis
  class FeedGenerator
    property config : Config

    def initialize(@config : Config)
    end

    def generate_rss(posts : Array(Content), limit : Int32 = 20) : String
      recent_posts = posts.select(&.is_post_layout?).first(limit)

      <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <title>#{escape_xml(@config.title)}</title>
          <description>#{escape_xml(@config.description)}</description>
          <link>#{@config.baseurl}</link>
          <atom:link href="#{@config.baseurl}/feed.xml" rel="self" type="application/rss+xml"/>
          <language>en-us</language>
          <lastBuildDate>#{Time.utc.to_rfc2822}</lastBuildDate>
          <generator>Lapis #{Lapis::VERSION}</generator>
          #{generate_rss_items(recent_posts)}
        </channel>
      </rss>
      XML
    end

    def generate_atom(posts : Array(Content), limit : Int32 = 20) : String
      recent_posts = posts.select(&.is_post_layout?).first(limit)
      updated = recent_posts.first?.try(&.date) || Time.utc

      <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>#{escape_xml(@config.title)}</title>
        <subtitle>#{escape_xml(@config.description)}</subtitle>
        <link href="#{@config.baseurl}/feed.atom" rel="self"/>
        <link href="#{@config.baseurl}"/>
        <updated>#{updated.to_rfc3339}</updated>
        <id>#{@config.baseurl}/</id>
        <generator version="#{Lapis::VERSION}">Lapis</generator>
        #{generate_atom_entries(recent_posts)}
      </feed>
      XML
    end

    def generate_json_feed(posts : Array(Content), limit : Int32 = 20) : String
      recent_posts = posts.select(&.is_post_layout?).first(limit)

      # Use JSON::Builder for structured JSON generation
      JSON.build do |json|
        json.object do
          json.field "version", "https://jsonfeed.org/version/1"
          json.field "title", @config.title
          json.field "description", @config.description
          json.field "home_page_url", @config.baseurl
          json.field "feed_url", "#{@config.baseurl}/feed.json"
          json.field "items" do
            json.array do
              recent_posts.each do |post|
                json.object do
                  json.field "id", "#{@config.baseurl}#{post.url}"
                  json.field "title", post.title
                  json.field "content_html", post.content
                  json.field "url", "#{@config.baseurl}#{post.url}"
                  json.field "date_published", post.date.try(&.to_rfc3339) || ""
                  json.field "date_modified", post.date.try(&.to_rfc3339) || ""
                  json.field "author" do
                    json.object do
                      json.field "name", post.author || @config.author
                    end
                  end
                  json.field "tags" do
                    json.array do
                      post.tags.each do |tag|
                        json.string tag
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    private def generate_rss_items(posts : Array(Content)) : String
      posts.map do |post|
        pub_date = post.date ? post.date.not_nil!.to_rfc2822 : Time.utc.to_rfc2822

        <<-XML
        <item>
          <title>#{escape_xml(post.title)}</title>
          <description>#{escape_xml(post.excerpt)}</description>
          <link>#{@config.baseurl}#{post.url}</link>
          <guid isPermaLink="true">#{@config.baseurl}#{post.url}</guid>
          <pubDate>#{pub_date}</pubDate>
          #{post.author ? "<author>#{escape_xml(post.author.not_nil!)}</author>" : ""}
          #{generate_rss_categories(post.tags + post.categories)}
        </item>
        XML
      end.join("\n")
    end

    private def generate_atom_entries(posts : Array(Content)) : String
      posts.map do |post|
        updated = post.date ? post.date.not_nil!.to_rfc3339 : Time.utc.to_rfc3339

        <<-XML
        <entry>
          <title>#{escape_xml(post.title)}</title>
          <link href="#{@config.baseurl}#{post.url}"/>
          <updated>#{updated}</updated>
          <id>#{@config.baseurl}#{post.url}</id>
          <content type="html">#{escape_xml(post.content)}</content>
          <summary>#{escape_xml(post.excerpt)}</summary>
          #{post.author ? "<author><name>#{escape_xml(post.author.not_nil!)}</name></author>" : ""}
          #{generate_atom_categories(post.tags + post.categories)}
        </entry>
        XML
      end.join("\n")
    end

    private def generate_rss_categories(categories : Array(String)) : String
      categories.map do |category|
        %(<category>#{escape_xml(category)}</category>)
      end.join("\n")
    end

    private def generate_atom_categories(categories : Array(String)) : String
      categories.map do |category|
        %(<category term="#{escape_xml(category)}"/>)
      end.join("\n")
    end

    private def escape_xml(text : String) : String
      text.gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub("\"", "&quot;")
          .gsub("'", "&#39;")
    end
  end

  class SitemapGenerator
    property config : Config

    def initialize(@config : Config)
    end

    def generate(all_content : Array(Content)) : String
      <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        #{generate_homepage_entry}
        #{generate_content_entries(all_content)}
        #{generate_archive_entries(all_content)}
      </urlset>
      XML
    end

    private def generate_homepage_entry : String
      <<-XML
      <url>
        <loc>#{@config.baseurl}/</loc>
        <changefreq>daily</changefreq>
        <priority>1.0</priority>
        <lastmod>#{Time.utc.to_s(Lapis::DATE_FORMAT_SHORT)}</lastmod>
      </url>
      XML
    end

    private def generate_content_entries(content : Array(Content)) : String
      content.map do |item|
        last_mod = item.date ? item.date.not_nil!.to_s(Lapis::DATE_FORMAT_SHORT) : Time.utc.to_s(Lapis::DATE_FORMAT_SHORT)
        priority = item.is_post_layout? ? "0.8" : "0.9"
        changefreq = item.is_post_layout? ? "monthly" : "yearly"

        <<-XML
        <url>
          <loc>#{@config.baseurl}#{item.url}</loc>
          <lastmod>#{last_mod}</lastmod>
          <changefreq>#{changefreq}</changefreq>
          <priority>#{priority}</priority>
        </url>
        XML
      end.join("\n")
    end

    private def generate_archive_entries(content : Array(Content)) : String
      entries = [] of String

      # Posts archive
      if content.any?(&.is_post_layout?)
        entries << <<-XML
        <url>
          <loc>#{@config.baseurl}/posts/</loc>
          <changefreq>weekly</changefreq>
          <priority>0.7</priority>
        </url>
        XML
      end

      # Tag pages
      tags = content.flat_map(&.tags).uniq
      tags.each do |tag|
        tag_slug = tag.downcase.gsub(/[^a-z0-9]/, "-")
        entries << <<-XML
        <url>
          <loc>#{@config.baseurl}/tags/#{tag_slug}/</loc>
          <changefreq>monthly</changefreq>
          <priority>0.5</priority>
        </url>
        XML
      end

      entries.join("\n")
    end
  end
end