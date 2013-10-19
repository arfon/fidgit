web: bundle exec rackup config.ru -p $PORT
worker: bundle exec sidekiq -r ./fidgit.rb -c 5 -v