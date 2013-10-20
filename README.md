Fidgit
======

Figshare and Git(Hub). By Arfon Smith.

What this does
--------------

This is a proof of concept integration between a GitHub repo and Figshare in an effort to get a [DOI](http://en.wikipedia.org/wiki/Digital_object_identifier) for a GitHub repository. When a repository is tagged for release on GitHub Fidgit will import the release into Figshare thus giving the code bundle a DOI. In a somewhat meta fashion, Fidgit is publishing itself to Figshare. It's DOI is [http://dx.doi.org/10.6084/m9.figshare.828487](http://dx.doi.org/10.6084/m9.figshare.828487).

Fidgit isn't really designed for 'production' use for example there's little or no error handling but hopefully there's some value here.

Getting started
---------------

### Access codes

First you need to get yourself a personal access token from your [GitHub profile](https://github.com/settings/applications) (this is going to be the 'github\_token' key in setup.toml) and get some OAuth tokens from [Figshare](http://figshare.com/account/applications). You need to create an application - any URL will work, it's not important for this - and keep a record all four access codes (consumer\_key, consumer\_token etc).

**Important** - If you want to publish code bundles to public articles on Figshare then you'll need to set the permissions for this application to allow public read/write access. Currently this isn't a huge issue though as Fidgit won't publish an unpublished article on Figshare (it will just upload a new code bundle to the unpublished article).

![Figshare](https://raw.github.com/arfon/fidgit/master/screens/figshare_applications.png)

### Heroku stuff

Fidgit is designed to run nicely on Heroku with two dynos, one web and one worker and a couple of free addons for MongoDB and a Redis server for Sidekiq (that does all of the background download from GitHub and then upload to Figshare).

![Heroku](https://raw.github.com/arfon/fidgit/master/screens/heroku.png)
