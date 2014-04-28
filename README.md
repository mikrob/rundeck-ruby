[![Gem Version](https://badge.fury.io/rb/rundeck-ruby.svg)](http://badge.fury.io/rb/rundeck-ruby)

# Rundeck-ruby

Like the name says, these are ruby bindings for the rundeck API

## Installation

The usual stuff: 

Add this line to your application's Gemfile:

    gem 'rundeck-ruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rundeck-ruby

## Getting started

So, you're not going to be using your username and password in this
library. Instead it uses rundeck's token-based authentication for
everything. See [the API docs](http://rundeck.org/docs/api/#token-authentication) for
instructions about generating a token.

## Command-line usage

This gem installs a binstub named `rundeck`.
Surprising, huh? Anyway, `rundeck` does one thing: execute jobs. Oh, you
want more? Well then, send a pull request, buddy.

The USAGE line:
```
rundeck exec <url> <token> <job guid> [<exec args>]
```

For example
```
$ rundeck exec https://my.server afdDSFasdfASD4334fasdfaasWERsW23423
cd51b400-aad2-0131-c7f8-0438353e293e -arg0 1234 - arg1 blah
https://my.server/executions/1234
```

That will connect to your rundeck server `my.server` using your auth
token, find job cd51b400-aad2-0131-c7f8-0438353e293e and execute it. It
prints out the url of the resulting execution.

"But that's a lot of parameters," you say? Well, if you've got a better idea, submit a pull request. Also, you're probably going to `alias` common executions anyway, so it's really not too bad.

## Library usage

### Connecting

Connections to your rundeck server are handled with the `Session` class.
Like so:
```
require 'rundeck-ruby'
session = Rundeck::Session('https://my.server', 'my token')
```
That's it. You have a session.

From there you can get a hash of some of the server's system information:
```
info_hash = session.system_info
```

### Listing Projects
The other thing the session lets you do get an array of your projects:
```
names = session.projects.map(&:name)
```

To get a single project, any of these will work:
```
project = session.projects.find{|p| p.name == "ReallyImportantProject"}
project = session.project("ReallyImportantProject")
project = Rundeck::Project.find(session, "ReallyImportantProject")
```

### Listing Jobs
From each project, you can get a list of jobs. This code:
```
session.projects.first.jobs.map(&:name)
```
will give you a list of jobs in the project.

You can get a single job object from the project in any of these ways:
```
job = project.jobs.find{|j| j.name == "MyJob"} # When you only have the name
job = project.job_by_id(the_job_guid)
```

You can skip right over the project and go straight to the job too:
```
job = Rundeck::Job.find(session, the_job_guid)
```

### Executing a job
Once you have a job object, you can work with its executions. To execute
the job, do this:
```
execution = job.execute!("some fancy job arguments")
```

### Finding executions

To get all executions from a job, do this:
```
executions = job.executions
```

If your rundeck is like mine, then there will be a boatload of executions in
each job, so getting all of them will be a pain. Unnecessary, too. To
filter down the results, do this:
```
active_executions = job.executions do |query|
  query.status = :failed
  query.max = 2
  query.offset = 100
end
```
It does what it looks like.

...or, for the whole project:
```
active_executions = Rundeck::Execution.where(project) do |query|
  query.status = :failed
  query.max = 2
  query.offset = 100
end
```

To get the valid statuses, ask the query object:
```
statuses = []
active_executions = job.executions do |query|
  statuses = query.class.valid_statuses
end
puts statuses
```
Spoiler: they're one of the following: `succeeded`, `failed`, `aborted`, `running`, or `nil`.

### Execution output
To get the output from an execution, ask it:
```
output = execution.output
```

`output` will be a hash containing the following keys: `id`,
`completed`, `hasFailedNodes`, `log`. `log` will, in turn, be a hash of
hostnames to log entries, which will be self-explanatory

## Contributing

[![Code Climate](https://codeclimate.com/github/jonp/rundeck-ruby.png)](https://codeclimate.com/github/jonp/rundeck-ruby)

The usual boilerplate:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Wishlist

If you want to contribute, here's what I'd like to do sooner rather than
later:

* Add execution tailing to the `rundeck` binstub, à la:

```
rundeck tail <execution url> <token>
```

...or...

```
rundeck exec -tail ...the other parameters...
```

* Running ad-hoc commands, both in irb and with the binstub
* Unit tests. While normally more of a TDDer than most, I find writing
  tests for API wrappers tedious at best. It should probably be done,
though.
