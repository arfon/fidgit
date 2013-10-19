#!/usr/bin/env rake

require './fidgit.rb'
require 'toml'

desc 'Bootstrap GitHub repos'
task :bootstrap_repos do  
  Repository.delete_all
  
  incoming = TOML.load_file("setup.toml")
  incoming['repos'].each do |key, val|
    repository = Repository.create( :name => val["name"],
                                    :github_address => val["location"],
                                    :figshare_article_id => val["figshare_article_id"],
                                    :secret => val["secret"])
    
    puts "Created #{repository.github_address} : #{repository.secret}"
  end

end

desc 'Setup JSON payload to post release information to Fidgit address'
task :setup_payloads do
  unless File.exists?("setup.toml")
    puts "Have you set up your config yet? See setup.toml.example"
    exit 1
  end
  
  incoming = TOML.load_file("setup.toml")
  
  # GITHUB_TOKEN is instantiated in fidgit.rb
  client = Octokit::Client.new(:access_token => GITHUB_TOKEN)

  incoming['repos'].each do |key, val|
    client.create_hook(
      "#{client.user.login}/#{val["name"]}",
      "web",
      {
        :url => "#{FIDGIT_LOCATION}/releases?secret=#{val["secret"]}",
        :content_type => "json"
      },
      {
        :events => ["release"],
        :active => true
      }
    )
    puts "Created hook for #{client.user.login}/#{val["name"]} posting to #{FIDGIT_LOCATION}/releases?secret=#{val["secret"]}"
  end
end