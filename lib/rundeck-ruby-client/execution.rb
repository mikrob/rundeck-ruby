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

      #sort the output by node
      ret = result['output'].slice(*%w(id completed hasFailedNodes))
      ret['log'] = result['output']['entries']['entry'].group_by{|e| e['node']}
      ret
    end

    def wait title, interval, timeout
      puts "[#{Time.now}] Waiting for #{title}"
      start = Time.now.to_i
      stop = start + timeout
      while Time.now.to_i < stop
             begin
                     if yield
                            puts "[#{Time.now}] ok !, duration #{Time.now.to_i - start}"
                            return
                     end
             rescue
             end
             $stdout.write "[#{Time.now}] #{title} .\n"
             $stdout.flush
             sleep interval
      end
      raise "Timeout while waiting end of #{title}"
    end

    def wait_end interval, timeout
      follow_execs = nil
      wait "job #{@job.name}, execution #{@id} to be finished", interval, timeout do
        follow_execs = @job.executions.select{|exec| exec.id == @id}
        follow_execs.first.status != :running
      end
      follow_execs.first.output
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

