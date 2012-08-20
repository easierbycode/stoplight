require 'nokogiri'
require 'open-uri'

module Stoplight::Providers
  class Teamcity < Provider
    def provider
      'teamcity'
    end

    def with_zero n
      (n > 10) ? n : "0#{n}"
    end

    def projects
      page = Nokogiri::HTML(open('http://174.77.67.250:8080/externalStatus.html'))
      @projects = []

      page.css('tr').each do |tr|
        if tr.at_css('.buildConfigurationName')
          project = {}

          project[:name] = tr.css('.buildConfigurationName').first.content.strip
          project[:build_url] = tr.css('.buildTypeName').first['href']
          project[:last_build_id] = tr.css('.teamCityBuildNumber a').first.content
          dt_str = tr.css('.date').first.content
          dt = Date._parse(dt_str)
          project[:last_build_time] = "#{dt[:year]}-#{with_zero(dt[:mon])}-#{with_zero(dt[:mday])}T#{with_zero(dt[:hour])}:#{with_zero(dt[:min])}:00Z"
          if /error.gif/ =~ tr.css('img').first['src']
            project[:last_build_status] = nil
            project[:current_status] = nil
          else
            project[:last_build_status] = 0
            project[:current_status] = 0
          end

          @projects.push Stoplight::Project.new(project)
        end
      end

      #@projects ||= [
      #    Stoplight::Project.new({
      #                               :name => 'Sample Project',
      #                               :build_url => 'http://www.example.com/',
      #                               :last_build_id => '1',
      #                               :last_build_time => '',
      #                               :last_build_status => 0,
      #                               :current_status => 0
      #                           })
      #]
    end
  end
end
