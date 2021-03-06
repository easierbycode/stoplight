class Project extends Backbone.Model

class ProjectCollection extends Backbone.Collection
  model: Project
  url: '/projects.json'

Projects = new ProjectCollection
Projects.comparator = (p)->
  new Date(p.get('last_build_time')).getTime()*-1

@Projects = Projects
