%%%-------------------------------------------------------------------
%%% @author uqon
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. sty 2015 14:38
%%%-------------------------------------------------------------------
-module(pubsub_supervisor).
-author("uqon").

-export([start/0, init/1]).

start() ->
  spawn(pubsub_supervisor, init, [self()]),
  loop().

init(PID) ->
  pubsub_subscriber:start(PID, 1),
  pubsub_subscriber:start(PID, 2),
  pubsub_subscriber:start(PID, 3),

  pubsub_publisher:start(PID).

loop() ->
  receive
    stop -> ok;
    A -> io:format("~s", [A]),
      loop()
  after 3000 -> ok
  end.