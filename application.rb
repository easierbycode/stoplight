configure {
  set :root, File.dirname(__FILE__)
}

get '/foo' do
  status 200
end

#
# GET /projects.json
#
# Load the initial build screen
#
get '/projects.json' do
  load_projects
  render :rabl, :index, :format => 'json'
end

#
# GET '/:project_name'
#
# Returns a PNG corresponding to the current build status
#
get '/:project_name.png' do |project_name|
  load_projects

  project = @projects.find { |project| project.name == project_name }

  unless project.nil?
    # if the project is done, show the status, otherwise, show it's building
    project_state = project.built? ? project.last_build_status : project.current_status

    image = case project_state
      when 'passed' then 'passing'
      when 'failed' then 'failing'
      else 'unknown'
    end

    content_type 'image/png'
    File.read("./public/images/status/#{image}.png")
  else
    status 404
  end
end


private
# Load the servers and projects from the YAML file
#def load_projects
#  @servers ||= YAML::load(File.read('config/servers.yml'))
#
#  @projects = @servers.collect do |server|
#    server_projects = get_server(server).projects
#
#    # if server['projects'] is defined, we only want those projects
#    if server['projects']
#      regexes = collect_regexes(server['projects'])
#      server_projects.select { |server_project|
#        regexes.any?{ |regex| server_project.name =~ regex }
#      }
#    elsif server['ignored_projects']
#      regexes = collect_regexes(server['ignored_projects'])
#      server_projects.reject { |server_project|
#        regexes.any?{ |regex| server_project.name =~ regex }
#      }
#    else
#      server_projects
#    end
#  end.compact.flatten
#end

def with_zero n
  (n > 10) ? n : "0#{n}"
end

def load_projects
  page = Nokogiri::HTML(open('http://174.77.67.250:8080/externalStatus.html'))
  @projects = []
  @buildTypeName = ''

  page.css('tr').each do |tr|
    if tr.at_css('.projectName')
      @buildTypeName = tr.css('.projectName').first.content
    end
    if tr.at_css('.buildConfigurationName')
      project = {}

      project[:name] = tr.css('.buildConfigurationName').first.content.strip + " (#{@buildTypeName})"
      project[:build_url] = tr.css('.buildTypeName').first['href']
      project[:last_build_id] = tr.css('.teamCityBuildNumber a').first.content.delete('#').to_i
      dt_str = tr.css('.date').first.content
      dt = Date._parse(dt_str)
      project[:last_build_time] = "#{dt[:year]}-#{with_zero(dt[:mon])}-#{with_zero(dt[:mday])}T#{with_zero(dt[:hour])}:#{with_zero(dt[:min])}:00Z"
      if /error.gif/ =~ tr.css('img').first['src']
        project[:last_build_status] = 1
        project[:current_status] = 0
      else
        project[:last_build_status] = 0
        project[:current_status] = 0
      end

      @projects.push Stoplight::Project.new(project)
    end
  end
end

def collect_regexes(projects)
  projects.collect do |j|
    if j =~ %r{^/.*/$}
      Regexp.new(j[1..(j.size-2)])
    else
      Regexp.new("^#{Regexp.escape(j)}$")
    end
  end
end

# Attemps to find the class associated with a given server type.
# Throws an exception if the class is not found
def get_server(server)
  server_type = server['type'].camelize
  begin
    klass = "Stoplight::Providers::#{server_type}".constantize
  rescue NameError => e
    raise Stoplight::Exceptions::UnknownProviderError, "Could not load provider with class name `#{server_type}`"
  end

  klass.new(server)
end
