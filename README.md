Fidgit
======

Figshare and Git(Hub). By Arfon Smith.

What this does
--------------

This is a proof of concept integration between a GitHub repo and Figshare in an effort to get a [DOI](http://en.wikipedia.org/wiki/Digital_object_identifier) for a GitHub repository. When a repository is tagged for release on GitHub Fidgit will import the release into Figshare thus giving the code bundle a DOI. In a somewhat meta fashion, Fidgit is publishing itself to Figshare. Its DOI is [http://dx.doi.org/10.6084/m9.figshare.828487](http://dx.doi.org/10.6084/m9.figshare.828487).

Fidgit isn't really designed for 'production' use, for example there's little or no error handling but hopefully there's some value here.

How it does it
--------------

Both GitHub and Figshare have pretty fully-featured APIs. Fidgit sits inbetween them listening out for [releases](https://github.com/blog/1547-release-your-software) and when it hears about one (through the webhook POST from GitHub) it downloads the release and pushes it to a predefined Figshare dataset.

Internally, Fidgit represents a _Repository_ and has the concept of a _Release_ which means it's also keeping track of the releases from your GitHub repository.

Getting started
---------------

### Access codes

First you need to get yourself a personal access token from your [GitHub profile](https://github.com/settings/applications) (this is going to be the 'github\_token' key in setup.toml) and get some OAuth tokens from [Figshare](http://figshare.com/account/applications). You need to create an application - any URL will work, it's not important for this - and keep a record all four access codes (consumer\_key, consumer\_token etc).

**Important** - If you want to publish code bundles to public articles on Figshare then you'll need to set the permissions for this application to allow public read/write access. Currently this isn't a huge issue though as Fidgit won't publish an unpublished article on Figshare (it will just upload a new code bundle to the unpublished article).

![Figshare](https://raw.github.com/arfon/fidgit/master/screens/figshare_applications.png)

### Heroku stuff

Fidgit is designed to run nicely on Heroku with two dynos, one web and one worker and a couple of free addons for MongoDB and a Redis server for Sidekiq (that does all of the background download from GitHub and then upload to Figshare).

![Heroku](https://raw.github.com/arfon/fidgit/master/screens/heroku.png)

Describing all of the Heroku setup is out of the scope of this introduction but as long as you configure it with a single web dyno and a single worker, a MongoHQ and Redistogo free account then you should be golden.

### GitHub stuff

You'll need an open source repository that you want to push to Figshare.

### Figshare stuff

You'll need an article to push to on Figshare. This can be made through the user-interface or API. You just need the integer id of the article for the configuration later.

Configuring Fidgit
------------------

Once you have your Heroku application up and running and your Figshare and GitHub keys you'll need to copy the setup.toml.example file to 'setup.toml'. An example config is below:

```toml

[setup] 
github_token = "a3133YBT45aW3auFd95n"
fidgit_location = "http://fidgit.arfon.org"
figshare_consumer_key = "a3133YBT45aW3auFd95n"
figshare_consumer_token = "a3133YBT45aW3auFd95n"
figshare_oauth_token = "a3133YBT45aW3auFd95n"
figshare_oauth_secret = "a3133YBT45aW3auFd95n"

[repos]
  [repos.fidgit]
  name = "fidgit"
  location = "https://github.com/arfon/fidgit"
  figshare_article_id = 828487
  secret = "a3133YBT45aW3auFd95n"
```

Here we're setting the location of your Fidgit instance (your Heroku application address), your GitHub personal access token and your Figshare OAuth credentials.

Next we're setting the repositories that we'd like to create DOIs for on Figshare. Note this is an array in the TOML config, that is, we can support a number of linkages. Important things to realise here:

* 'name' is the name of your repository on GitHub
* 'location' is the HTML url of the repository. Note that at this time Fidgit only supports open source repos.
* 'figshare\_article_id' is the integer article id of your Figshare
* 'secret' is a string that you have made up that is used in the webhook push from GitHub to Fidgit. It's basically an API key to Fidgit for a repo.

Bootstraping Fidgit
-------------------

Now you've got your configuration file setup you need to push the code to your Heroku application and run a couple of rake tasks to initialize the application. They are:

```ruby
rake bootstrap_repos
rake setup_payloads
```

If everything goes to plan then these tasks should run without error and should produce a small amount of debug information. Significantly the second task uses the GitHub API to configure a webhook that posts a JSON payload to your Fidgit application each time a new release is issued. You can check that this is working by going to the service hooks page under 'settings' for your repo.

![Webhook](https://raw.github.com/arfon/fidgit/master/screens/webhook.png)

That's a wrap!
--------------

And that's about it. If you now create a new release on GitHub then you should see this code bundle being mirrored to your specified location on Figshare. Check out the [Fidgit one here](http://dx.doi.org/10.6084/m9.figshare.828487). Any questions, comments, concerns post an issue.

![DOIed](https://raw.github.com/arfon/fidgit/master/screens/figshare_article.png)
