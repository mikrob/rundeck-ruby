module Rundeck
  class Project
    def self.all(session)
      @all ||= begin
                 result = session.get('api/3/projects', 'result', 'projects', 'project') || []
                 result.map{|hash| Project.new(session, hash)}
               end
    end

    def self.find(session, name)
      all(session).first{|p| p.name == name}
    end

    def initialize(session, hash)
      @session = session
      @name = hash['name']
    end
    attr_reader :session, :name

    def jobs(force_reload = false)
      return @jobs unless @jobs.nil? || force_reload
      result = session.get("api/2/jobs?project=#{name}", 'result', 'jobs', 'job') || []
      @jobs = result.map{|hash| Job.from_hash(session, hash)}
    end

    def job_by_id(id)
      jobs.first{|j| j.id == id}
    end
  end
end
