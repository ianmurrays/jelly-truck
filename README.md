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

Practically all the basic functionality is there, except for most REST API methods (like listing channels and stuff like that). Presence and Private channels are supported. The last Pusher JS client that's supported is version 1.9, since they introduced [sockjs](https://github.com/sockjs/sockjs-node) (which is not supported by jelly-truck just yet).

As it is, jelly-truck isn't really scalable since it stores everything in memory. Redis as a decoupled database is planned for future releases.

You can always check out the project's [milestones](https://github.com/ianmurrays/jelly-truck/issues/milestones) to see what's planned and what's already done.

How can I help?
---------------

Check out the [issues](https://github.com/ianmurrays/jelly-truck/issues). If you want to contribute, please:

  1. Fork the repository
  2. Checkout the `development` branch
  3. Create a feature branch off `development`
  4. Do some ninja programming
  5. Create a pull request
