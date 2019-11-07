-module(deribit_api).

-export([
  open/0, open/1, open/2, open/3,
  close/1,
  account/1, account/2,
  buy/2, buy/3,
  sell/2, sell/3,
  cancel/2, cancel/3,
  cancelall/2, cancelall/3,
  edit/2, edit/3,
  getopenorders/2, getopenorders/3,
  positions/1, positions/2,
  orderhistory/1, orderhistory/2, orderhistory/3,
  tradehistory/2, tradehistory/3,
  getinstruments/1, getinstruments/2,
  getcurrencies/1, getcurrencies/2,
  getorderbook/2, getorderbook/3,
  getsummary/2, getsummary/3,
  index/1, index/2, index/3,
  getlasttrades/2, getlasttrades/3,
  subscribe/2, subscribe/3,
  unsubscribe/1, unsubscribe/2
]).

-type connection()      :: pid().
-type connection_options() :: websocket | http | url().
-type url()             :: string().
-type instrument()      :: string() | binary().
-type trade_id()        :: integer().
-type result()          :: {ok, any()} | {error, any()} | reference() | ok.
-type option()          :: {async} | {async, fun( (result()) -> ok )}.
-type options()         :: list(option()).

-spec open() -> Result when
  Result     :: {ok, connection()} | {error, Reason},
  Reason     :: string() | binary().
open() ->
  open("", "", websocket).

-spec open(connection_options()) -> Result when
  Result     :: {ok, connection()} | {error, Reason},
  Reason     :: string() | binary().
open(Mode) ->
  open("", "", Mode).

-spec open(AccessKey, AccessSecret) -> Result when
  AccessKey    :: string(),
  AccessSecret :: string(),
  Result       :: {ok, connection()} | {error, Reason},
  Reason       :: string() | binary().
open(AccessKey, AccessSecret) ->
  open(AccessKey, AccessSecret, websocket).

-spec open(AccessKey, AccessSecret, connection_options()) -> Result when
  AccessKey    :: string(),
  AccessSecret :: string(),
  Result       :: {ok, connection()} | {error, Reason},
  Reason       :: string() | binary().

open(AccessKey, AccessSecret, http) ->
  open(AccessKey, AccessSecret, "https://www.deribit.com");
open(AccessKey, AccessSecret, websocket) ->
  open(AccessKey, AccessSecret, "wss://www.deribit.com");
open(AccessKey, AccessSecret, Url) ->
  case http_uri:parse(Url, [{scheme_defaults, [{ws, 80}, {wss, 443} | http_uri:scheme_defaults()]}]) of
    {ok, {Protocol, _, Host, Port, _, _}} ->
      if
        Protocol =:= http orelse Protocol =:= https ->
          deribit_api_http:start(AccessKey, AccessSecret, Protocol, Host, Port);
        Protocol =:= ws orelse Protocol =:= wss ->
          deribit_api_websocket:start(AccessKey, AccessSecret, Host, Port)
      end;
    _ ->
      {error, wrong_url}
  end.

-spec close(connection()) -> ok.
close(Connection) ->
  gen_server:stop(Connection).

-spec buy(connection(), Params) -> result() when
    Params     :: #{
                    instrument := instrument(),
                    quantity   := number(),
                    price      := number(),
                    post_only  => boolean(),
                    label      => string() | binary()
                   }.
buy(Connection, Params) when is_map(Params) ->
  request(Connection, "/api/v1/private/buy", Params).

-spec buy(connection(), Params, options()) -> result() when
    Params     :: #{
                    instrument := instrument(),
                    quantity   := number(),
                    price      := number(),
                    post_only  => boolean(),
                    label      => string() | binary()
                  }.
buy(Connection, Params, Options) when is_map(Params), is_list(Options)  ->
  request(Connection, "/api/v1/private/buy", Params, Options).

-spec sell(connection(), Params) -> result() when
  Params     :: #{
                  instrument := instrument(),
                  quantity   := number(),
                  price      := number(),
                  post_only  => boolean(),
                  label      => string() | binary()
                 }.
sell(Connection, Params) when is_map(Params)  ->
  request(Connection, "/api/v1/private/sell", Params).

-spec sell(connection(), Params, options()) -> result() when
  Params     :: #{ instrument := instrument(),
                   quantity   := number(),
                   post_only  => boolean(),
                   label      => string() | binary()
                 }.
sell(Connection, Params, Options) when is_map(Params), is_list(Options)  ->
  request(Connection, "/api/v1/private/sell", Params, Options).

-spec cancel(connection(), integer()) -> result().
cancel(Connection, OrderId) ->
  request(Connection, "/api/v1/private/cancel", #{ orderId => OrderId }).

-spec cancel(connection(), integer(), options()) -> result().
cancel(Connection, OrderId, Options) when is_list(Options) ->
  request(Connection, "/api/v1/private/cancel", #{ orderId => OrderId }, Options).


-spec cancelall(connection(), Type) -> result() when
  Type     :: all | futures | options.
cancelall(Connection, Type) ->
  request(Connection, "/api/v1/private/cancelall", #{ type => Type }).

-spec cancelall(connection(), Type, options()) -> result() when
  Type     :: all | futures | options.
cancelall(Connection, Type, Options) when is_list(Options) ->
  request(Connection, "/api/v1/private/cancelall", #{ type => Type }, Options).

-spec account(connection()) -> result().
account(Connection) ->
  request(Connection, "/api/v1/private/account", #{}).

-spec account(connection(), options()) -> result().
account(Connection, Options) when is_list(Options) ->
  request(Connection, "/api/v1/private/account", #{}, Options).

-spec edit(connection(), Params) -> result() when
  Params     :: #{
                  orderId  := integer(),
                  quantity := number(),
                  price    := number()
                }.
edit(Connection, Params) when is_map(Params)  ->
  request(Connection, "/api/v1/private/edit", Params).

-spec edit(connection(), Params, options()) -> result() when
  Params     :: #{
                  orderId  := integer(),
                  quantity := number(),
                  price    := number()
                }.
edit(Connection, Params, Options) when is_map(Params), is_list(Options)  ->
  request(Connection, "/api/v1/private/edit", Params, Options).

-spec getopenorders(connection(), Params) -> result() when
  Params     :: #{
                  instrument => instrument(),
                  orderId    => integer()
                }.
getopenorders(Connection, Params) when is_map(Params)  ->
  request(Connection, "/api/v1/private/getopenorders", Params).

-spec getopenorders(connection(), Params, options()) -> result() when
  Params     :: #{
                  instrument => instrument(),
                  orderId    => integer()
                }.
getopenorders(Connection, Params, Options) when is_map(Params), is_list(Options)  ->
  request(Connection, "/api/v1/private/getopenorders", Params, Options).

-spec positions(connection()) -> result().
positions(Connection) ->
  request(Connection, "/api/v1/private/positions", #{}).

-spec positions(connection(), options()) -> result().
positions(Connection, Options) ->
  request(Connection, "/api/v1/private/positions", #{}, Options).

-spec orderhistory(connection())  -> result().
orderhistory(Connection) ->
  request(Connection, "/api/v1/private/orderhistory", #{}).

-spec orderhistory(connection(), integer()) -> result();
                  (connection(), options()) -> result().
orderhistory(Connection, Count) when is_integer(Count) ->
  request(Connection, "/api/v1/private/orderhistory", #{ count => Count });
orderhistory(Connection, Options) when is_list(Options) ->
  request(Connection, "/api/v1/private/orderhistory", #{}, Options).

-spec orderhistory(connection(), integer(), options()) -> result().
orderhistory(Connection, Count, Options) when is_integer(Count) ->
  request(Connection, "/api/v1/private/orderhistory", #{ count => Count }, Options).

-spec tradehistory(connection(), Params) -> result() when
  Params     :: #{
                  instrument   := instrument() | all | futures | options,
                  count        => integer(),
                  startTradeId => trade_id()
                }.
tradehistory(State, Params) when is_map(Params)  ->
  request(State, "/api/v1/private/tradehistory", Params).

-spec tradehistory(connection(), Params, options()) -> result() when
  Params     :: #{
                  instrument   := instrument() | all | futures | options,
                  count        => integer(),
                  startTradeId => trade_id()
                }.
tradehistory(Connection, Params, Options) when is_map(Params), is_list(Options)  ->
  request(Connection, "/api/v1/private/tradehistory", Params, Options).

-spec getinstruments(connection()) -> result().
getinstruments(Connection) ->
  request(Connection, "/api/v1/public/getinstruments", #{}).

-spec getinstruments(connection(), options()) -> result().
getinstruments(Connection, Options) when is_list(Options) ->
  request(Connection, "/api/v1/public/getinstruments", #{}, Options).

-spec getcurrencies(connection()) -> result().
getcurrencies(Connection) ->
  request(Connection, "/api/v1/public/getcurrencies", #{}).

-spec getcurrencies(connection(), options()) -> result().
getcurrencies(Connection, Options) when is_list(Options) ->
  request(Connection, "/api/v1/public/getcurrencies", #{}, Options).

-spec getorderbook(connection(), instrument()) -> result().
getorderbook(State, Instrument) ->
  request(State, "/api/v1/public/getorderbook", #{ instrument => Instrument }).

-spec getorderbook(connection(), instrument(), options()) -> result().
getorderbook(State, Instrument, Options) when is_list(Options) ->
  request(State, "/api/v1/public/getorderbook", #{ instrument => Instrument }, Options).

-spec getsummary(connection(), instrument()) -> result().
getsummary(Connection, Instrument) ->
  request(Connection, "/api/v1/public/getsummary", #{ instrument => Instrument }).

-spec getsummary(connection(), instrument(), options()) -> result().
getsummary(Connection, Instrument, Options) when is_list(Options) ->
  request(Connection, "/api/v1/public/getsummary", #{ instrument => Instrument }, Options).

-spec index(connection()) -> result().
index(Connection) ->
  request(Connection, "/api/v1/public/index", #{}).

-spec index(connection(), options()) -> result().
index(Connection, Options) when is_list(Options) ->
  request(Connection, "/api/v1/public/index", #{}, Options).

-spec index(connection(), atom(), options()) -> result().
index(Connection, Currency, Options) when is_atom(Currency) andalso is_list(Options) ->
  request(Connection, "/api/v1/public/index", #{currency => Currency}).


-spec getlasttrades(connection(), Params) -> result() when
  Params     :: #{
                  instrument := instrument(),
                  since      => trade_id(),
                  count      => integer()
                }.
getlasttrades(Connection, Params) when is_map(Params)  ->
  request(Connection, "/api/v1/public/getlasttrades", Params).

-spec getlasttrades(connection(), Params, options()) -> result() when
  Params     :: #{
                  instrument := instrument(),
                  since      => trade_id(),
                  count      => integer()
                }.
getlasttrades(Connection, Params, Options) when is_map(Params), is_list(Options) ->
  request(Connection, "/api/v1/public/getlasttrades", Params, Options).


-spec subscribe(connection(), Params) -> result() when
  Params     :: #{
                  instrument := list(string()) | [all] | [futures] | [options] | [index],
                  event      := list(order_book | trade | user_order)
                }.
subscribe(Connection, Params) when is_map(Params) ->
  subscribe(Connection, Params).

-spec subscribe(connection(), Params, options()) -> result() when
  Params     :: #{
                  instrument := list(instrument()) | [all] | [futures] | [options] | [index],
                  event      := list(order_book | trade | user_order)
                }.
subscribe(Connection, Params, Options) when is_map(Params), is_list(Options) ->
  Instruments = maps:get(instrument, Params),
  Events = maps:get(event, Params),
  request(Connection, "/api/v1/private/subscribe", #{ instrument => {array, Instruments}, "event" => {array, Events}}, Options).

-spec unsubscribe(connection()) -> result().
unsubscribe(Connection) ->
  request(Connection, "/api/v1/private/unsubscribe", #{}).

-spec unsubscribe(connection(), options()) -> result().
unsubscribe(Connection, Options) when is_list(Options) ->
  request(Connection, "/api/v1/private/unsubscribe", #{}, Options).


request(Pid, Action, Data) ->
    deribit_api_utils:request(Pid, Action, Data).
request(Pid, Action, Data, Options) when is_list(Options) ->
    deribit_api_utils:request(Pid, Action, Data, Options).
