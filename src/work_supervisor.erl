%%%-------------------------------------------------------------------
%%% @author uqon
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. sty 2015 13:22
%%%-------------------------------------------------------------------
-module(work_supervisor).
-author("uqon").

%% API
-export([start/0, init/1]).

start() ->
  spawn(work_supervisor, init, [self()]),
  loop().

init(PID) ->
  work_subsriber:start(PID, 1),
  work_subsriber:start(PID, 2),
  work_subsriber:start(PID, 3),

  work_publisher:start(PID).

loop() ->
  receive
    stop -> ok;
    A -> io:format("~s", [A]),
      loop()
  after 3000 -> ok
  end.