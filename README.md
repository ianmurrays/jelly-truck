jelly-truck
===========

Jelly Truck is a [Pusher](http://pusher.com) clone written in node using coffeescript. It is in **very early stages of development**, so it is not usable in a production environment.

How do I even?
--------------

Clone the repository:

    git clone git@github.com:ianmurrays/jelly-truck.git

Install all dependencies

    npm install

Run the server

    ./bin/jelly-truck -a app_id -k app_key -s s0m3secre7

What is working?
----------------

Right now Jelly Truck only supports public channels. The web API to publish events isn't working, so you can't really do anything with it just yet. You can always check out the project's [milestones](https://github.com/ianmurrays/jelly-truck/issues/milestones) to see what's planned and what's already done.

How can I help?
---------------

Check out the [issues](https://github.com/ianmurrays/jelly-truck/issues). If you want to contribute, please:

  1. Fork the repository
  2. Checkout the `development` branch
  3. Create a feature branch off `development`
  4. Do some ninja programming
  5. Create a pull request
