%%%-------------------------------------------------------------------
%%% @author uqon
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. sty 2015 14:38
%%%-------------------------------------------------------------------
-module(pubsub_publisher).
-author("uqon").

-include_lib("amqp_client/include/amqp_client.hrl").

%% API
-export([start/1, init/1]).

start(PID) -> spawn(pubsub_publisher, init, [PID]).

init(PID) ->
  %%Start connection
  {ok, Connection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
  {ok, Channel} = amqp_connection:open_channel(Connection),

  %%Exchange declare
  amqp_channel:call(Channel, #'exchange.declare'{exchange = <<"pubsub_exchange">>, type = <<"fanout">>}),

  %%Publish messages
  timer:sleep(200),
  PID ! "[PUBLISHER] Starting publishing messages \n",
  loop(Channel, 1, PID),
  PID ! "[PUBLISHER] Stopping publishing messages \n",

  %%Close connection
  ok = amqp_channel:close(Channel),
  ok = amqp_connection:close(Connection),
  ok.

addToQueue(Channel, Num, PID) ->
  %%Prepare message
  Message = io_lib:format("Message: ~p", [Num]),
  Payload = list_to_binary(Message),
  PID ! io_lib:format("[PUBLISHER] Sent: <<~s>> ~n", [Message]),

  %%Publish message
  amqp_channel:cast(Channel,
    #'basic.publish'{exchange = <<"pubsub_exchange">>},
    #amqp_msg{props = #'P_basic'{delivery_mode = 2}, payload = Payload}).

loop(Channel, Num, PID) ->
  case Num of
    A when A < 21 ->
      addToQueue(Channel, Num, PID),
      timer:sleep(300),
      loop(Channel, Num + 1, PID);
    _ -> ok
  end.