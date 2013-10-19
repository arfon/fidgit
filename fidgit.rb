%w{rubygems sinatra mongo_mapper digest pry multi_json octokit erb sidekiq toml oauth}.each { |dep| require dep }

require 'net/http/post/multipart'

if ENV['MONGOHQ_URL']
  uri = URI.parse(ENV['MONGOHQ_URL'])
  MongoMapper.connection = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
  MongoMapper.database = uri.path.gsub(/^\//, '')
else
  MongoMapper.setup({"development" => { "host" => "localhost", "database" => "fidgit_development", "port" => 27017}}, 'development')
end

CONFIG = TOML.load_file("setup.toml")

# SETUP
GITHUB_TOKEN = CONFIG['setup']['github_token']
FIDGIT_LOCATION = CONFIG['setup']['fidgit_location']

class Repository
  include MongoMapper::Document
  
  key :name, String
  key :secret, String
  key :github_address, String
  key :tag, String
  key :commit, String
  key :figshare_article_id, String
  key :synced, Boolean, :default => false
  timestamps!
  
  many :releases
    
  def latest_releases
    releases.reverse.take(10)
  end
  
  def figshare_api_location
    "http://api.figshare.com/v1/my_data/articles/#{self.figshare_article_id}/files"
  end
  
  def github_zip_location
    "#{github_address}/archive/#{tag}.zip"
  end
  
  def update_releases(repository, release)
    client = Octokit::Client.new(:access_token => GITHUB_TOKEN)
    sha = client.tags(repository['full_name']).first.commit.sha
    # Update Repository commit
    self.releases << Release.new(:tag => release['tag_name'], :body => release)
    self.tag = release['tag_name']
    self.commit = sha
    save
  end
end

class Release
  include MongoMapper::EmbeddedDocument
  
  key :tag, String
  key :body, Hash
  timestamps!
  
  def prerelease?
    body['prerelease']
  end
end

class RepoWorker
  include Sidekiq::Worker
  
  def perform(fidgit_repo_id, repository, release)
    @fidgit_repository = Repository.find(fidgit_repo_id)
    @fidgit_repository.update_releases(repository, release)
    
    download(@fidgit_repository)
    upload(@fidgit_repository)
    
    # Mark as synced
    @fidgit_repository.synced = true
    @fidgit_repository.save
  end
  
  def download(fidgit_repository)
    `curl -o tmp/#{fidgit_repository.name}-#{fidgit_repository.tag}.zip -L #{fidgit_repository.github_zip_location}`
  end
  
  def upload(fidgit_repository)
    consumer = OAuth::Consumer.new(CONFIG['setup']['figshare_consumer_key'], CONFIG['setup']['figshare_consumer_token'],{:site=>"http://api.figshare.com"})
    token = { :oauth_token => CONFIG['setup']['figshare_oauth_token'],
              :oauth_token_secret => CONFIG['setup']['figshare_oauth_secret']
            }
            
    client = OAuth::AccessToken.from_hash(consumer, token)
        
    url = URI.parse(fidgit_repository.figshare_api_location)
    
    # Upload the file from tmp to Figshare.
    File.open("tmp/#{fidgit_repository.name}-#{fidgit_repository.tag}.zip") do |dataset|
      multipart = Net::HTTP::Put::Multipart.new url.path,
        "filedata" => UploadIO.new(dataset, "application/zip", "tmp/#{fidgit_repository.name}-#{fidgit_repository.tag}.zip")
      Net::HTTP.start(url.host, url.port) do |http|
        consumer.sign!(multipart, client)
        result = http.request(multipart)
      end
    end
  end
end

before do
  @fidgit_repository = Repository.find_by_secret(params[:secret])
  return status 404 unless @fidgit_repository
end

post '/releases' do
  @data = MultiJson.decode(request.body)
  @release = @data['release']
  @repository = @data['repository']
  RepoWorker.perform_async(@fidgit_repository.id, @repository, @release)
end

get '/repository' do
  erb :repository
end
