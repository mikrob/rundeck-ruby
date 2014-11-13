require 'timeout'
require 'pp'

module Rundeck
  class Execution
    def self.from_hash(session, hash)
      job = Job.from_hash(session, hash['job'])
      new(session, hash, job)
    end

    def initialize(session, hash, job)
      @id = hash['id']
      @url=hash['href']
      @url = URI.join(session.server, URI.split(@url)[5]).to_s if @url # They always return a url of "localhost" for their executions. Replace it with the real URL
      @status=hash['status'].to_sym
      @date_started = hash['date_started']
      @date_ended = hash['date_ended']
      @user = hash['user']
      @args = (hash['argstring'] || "").split
                                      .each_slice(2)
                                      .reduce({}){|acc,cur| acc[cur[0]] = cur[1]; acc}
      @job = job
      @session = session
    end
    attr_reader :id, :url, :status, :date_started, :date_ended, :user, :args, :job, :session

    def self.find(session, id)
      result = session.get("api/1/execution/#{id}", *%w(result executions execution))
      return nil unless result
      job = Job.find(session, result['job']['id'])
      return nil unless job
      Execution.new(session, result, job)
    end

    def self.where(project)
      qb = QueryBuilder.new
      yield qb if block_given?

      endpoint = "api/5/executions?project=#{project.name}#{qb.query}"
      pp endpoint
      results = project.session.get(endpoint, 'result', 'executions', 'execution') || []
      results = [results] if results.is_a?(Hash) #Work around an inconsistency in the API
      results.map {|hash| from_hash(project.session, hash)}
    end

    def output
      ret = session.get("api/9/execution/#{id}/output")
      result = ret['result']
      raise "API call not successful" unless result && result['success']=='true'
      ret = result['output'].slice(*%w(id completed hasFailedNodes))
      logs = result['output']['entries']['entry']
      if logs.class == Array
        logs = logs.group_by{|e| e['node']}
      else
        logs = {"localhost" => [logs]}
      end
      ret['log'] = logs
      ret = [ret] if ret.class != Array
      ret
    end

    # http request are done at each loop so, be nice with interval :)
    def wait_end interval, timeout
      Timeout.timeout(timeout) do
          exec = Execution::find(@session, @id)
        until exec.status != :running do
          exec = Execution::find(@session, @id)
          sleep interval
        end
      end
      self.output
    end

    class QueryBuilder
      attr_accessor :status, :max, :offset

      def self.valid_statuses
        %w(succeeded failed aborted running) << nil
      end

      def validate
        raise "Invalid requested status: #{status}" unless status.nil? || elf.class.valid_statuses.include?(status.to_s)
        raise "Invalid offset: #{offset}" unless offset.nil? || offset.to_i >= 0
        raise "Invalid max: #{max}" unless max.nil? || max.to_i >= 0
      end

      def query
        validate

        [
          "",
          status && "statusFilter=#{status}",
          max && "max=#{max.to_i}",
          offset && "offset=#{offset.to_i}",
        ].compact
          .join("&")
          .chomp("&")
      end
    end

  end
end

