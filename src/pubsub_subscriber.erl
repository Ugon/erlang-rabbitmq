%%%-------------------------------------------------------------------
%%% @author uqon
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. sty 2015 14:38
%%%-------------------------------------------------------------------
-module(pubsub_subscriber).
-author("uqon").

-include_lib("amqp_client/include/amqp_client.hrl").

%% API
-export([start/2, init/2]).

start(PID, Number) -> spawn(pubsub_subscriber, init, [PID, Number]).

init(PID, Number) ->
  %%Start connection
  {ok, Connection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  %%Exchange declare
  amqp_channel:call(Channel, #'exchange.declare'{exchange = <<"pubsub_exchange">>, type = <<"fanout">>}),

  %%Queue declare and bind
  #'queue.declare_ok'{queue = Queue} = amqp_channel:call(Channel, #'queue.declare'{exclusive = true}),
  amqp_channel:call(Channel, #'queue.bind'{exchange = <<"pubsub_exchange">>, queue = Queue}),

  %%Subscribe and receive confirmation
  amqp_channel:subscribe(Channel, #'basic.consume'{queue = Queue, no_ack = true}, self()),
  receive
    #'basic.consume_ok'{} -> ok
  end,

  %%Receive messages
  PID ! io_lib:format("[SUBSCRIBER ~p] Waiting for messages.~n", [Number]),
  loop(Channel, PID, Number),
  PID ! io_lib:format("[SUBSCRIBER ~p] Stopping waiting for messages.~n", [Number]),

  %%Close connection
  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

loop(Channel, PID, Number) ->
  receive
  %%Receive message
    {#'basic.deliver'{}, #amqp_msg{payload = Body}} ->

      %%Precess message
      PID ! io_lib:format("[SUBSCRIBER ~p] Received: ~p~n", [Number, Body]),
      timer:sleep(200 * Number * Number),

      loop(Channel, PID, Number)
  after 2000 -> ok
  end.