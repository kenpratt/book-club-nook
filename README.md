Book Club Nook
==============

Provides a nice interface to research and select books for book clubs. Currently online at [vancitybooknook.com](http://vancitybooknook.com/)

It pulls data from:

* Vancouver Public Library
* Goodreads
* Amazon

Requirements
------------

* Ruby 1.9+
* Bundler

Installation
------------

Install gems:

    bundle install --path=.gems --deployment

Set up config file;

    cp config.yml.example
    edit config.yml
    (Put in your API keys -- you may need to go get them)

Set up cron job to generate the book data and keep it up to data.

    crontab -e

Append this line:

    */15 * * * * cd /path/to/bookclubnook && /usr/local/bin/bundle exec ./generate_data.rb >> generate_data.log 2>&1
