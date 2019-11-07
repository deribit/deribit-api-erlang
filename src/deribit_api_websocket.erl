-module(deribit_api_websocket).
-behaviour(gen_server).

-export([
  start/4,
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3
]).

-record(state, {
  id = 0,
  state :: ready | not_configured | connecting | upgrading | up | broken,
  owner,
  key,
  secret,
  host,
  port,
  connection,
  ping_timer,
  pids_map = maps:new(),
  notifications_pid = null,
  last_pong,
  parent
}).

-define(TIMEOUT, 5000).
-define(DERIBIT_PING_TIME,   10000).
-define(MAX_NO_PONG_TIME, 30000000).

start(Key, Secret, Host, Port) ->
  case gen_server:start(?MODULE, [self(), Key, Secret, Host, Port, self()], []) of
    {ok, Pid} ->
      receive
        {Pid, connection_up} ->
          {ok, Pid}
      after
        ?TIMEOUT ->
          Pid ! stop,
          {error, timeout}
      end;
    Error ->
      Error
  end.

init([Owner, Key, Secret, Host, Port, Parent]) ->
  monitor(process, Owner),
  {ok, Connection} = gun:open(Host, Port),
  {ok, #state{
    owner = Owner,
    key = Key,
    secret = Secret,
    host = Host,
    port = Port,
    connection = Connection,
    state = connecting,
    parent = Parent}}.

handle_call({request, Action, Data, Pid}, _From, #state{ id = Id, key = Key, secret = Secret, pids_map = PidsMap, connection = Connection, notifications_pid = NotificationsPid } = State) ->
  NewNotificationsPid = case Action of
    "/api/v1/private/subscribe" -> Pid;
      _ -> NotificationsPid
  end,
  Signature = deribit_api_utils:generate_signature(Key, Secret, Action, Data),
  NewId = Id + 1,
  Request = #{
    id => NewId,
    action => list_to_binary(Action),
    arguments => deribit_api_utils:transform_map_keys_to_atom(Data),
    sig => list_to_binary(Signature)
  },
  JsonRequest = jiffy:encode(Request),
  gun:ws_send(Connection, {text, JsonRequest}),
  {reply, NewId, State#state{ pids_map = maps:put(NewId, Pid, PidsMap), notifications_pid = NewNotificationsPid, id = NewId }};
handle_call(_Request, _From, State) ->
  {reply, State, State}.

handle_cast(ping, State) ->
  gun:ws_send(State#state.connection, {text, <<"{\"id\":0,\"action\":\"/api/v1/public/ping\"}">>}),
  {noreply, State};
handle_cast(print_state, State) ->
  {noreply, State};
handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(stop, State) ->
  {stop, stopped, State#state{ state = broken }};
handle_info(ping, #state{last_pong = LastPong} = State) ->
  Diff = timer:now_diff(os:timestamp(), LastPong),
  case Diff > ?MAX_NO_PONG_TIME of
    true ->
      {stop, connection_broken, State#state{ state = broken }};
    false ->
      gen_server:cast(self(), ping),
      PingTimer = erlang:send_after(?DERIBIT_PING_TIME, self(), ping),
      {noreply, State#state{ ping_timer = PingTimer }}
  end;

handle_info({gun_ws, _Pid, {text, Text}}, #state{ pids_map = PidsMap, notifications_pid = NotificationsPid } = State) ->
  Json = jiffy:decode(binary_to_list(Text), [return_maps]),
  Result = case Json of
    #{ <<"notifications">> := Notifications       } -> {notifications, Notifications};
    #{ <<"success">> := true,  <<"message">> := <<"">>, <<"result">>  := R } -> {ok, R};
    #{ <<"success">> := true,  <<"result">> := <<"pong">> } -> {pong};
    #{ <<"success">> := true,  <<"message">> := M } -> {ok, M};
    #{ <<"success">> := true,  <<"result">>  := R } -> {ok, R};
    #{ <<"success">> := false, <<"message">> := M } -> {error, M};
    _ -> {error, <<"unknown response">>}
  end,

  case Result of
    {pong} ->
      {noreply, State#state{ last_pong = os:timestamp() }};
    {notifications, _} ->
      case NotificationsPid of
        _ when is_pid(NotificationsPid) ->
          NotificationsPid ! {self(), Result};
        _ when is_function(NotificationsPid) ->
          erlang:apply(NotificationsPid, [Result])
      end,
      {noreply, State};
    _ ->
      Id = maps:get(<<"id">>, Json, undefined),
      case Id of
        undefined ->
          {noreply, State};
        _ ->
          Key = maps:get(Id, PidsMap, undefined),
          case Key of
            undefined ->
              ok;
            _ when is_pid(Key) ->
              Key ! {self(), erlang:insert_element(1, Result, Id)};
            _ when is_function(Key) ->
              erlang:apply(Key, [Result])
          end,
          {noreply, State#state{pids_map = maps:remove(Id, PidsMap)}}
      end
  end;
handle_info({gun_ws_upgrade, _ConnPid, ok, _Headers}, #state{ parent = Parent } = State) ->
  PingTimer = erlang:send_after(?DERIBIT_PING_TIME, self(), ping),
  Parent ! {self(), connection_up},
  {noreply, State#state{state = up, ping_timer = PingTimer, last_pong = os:timestamp()}};
handle_info({gun_up, Connection, http}, State) ->
  gun:ws_upgrade(Connection, "/ws/api/v1/"),
  {noreply, State#state{ connection = Connection, state = upgrading, last_pong = os:timestamp()}};
handle_info({gun_error, _Pid, _Ref, _Reason} = _Err, #state{} = State) ->
  {stop, connection_broken, State};
handle_info({gun_down, _Pid, _, _, _, _}, #state{} = State) ->
  {stop, connection_down, State#state{ state = broken }};
handle_info({'DOWN',_,process,Pid,_}, #state{ owner = Pid } = State) ->
  {stop, shutdown, State};
handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, #state{ connection = undefined }) ->
  ok;
terminate(_Reason, #state{ connection = Connection }) ->
  gun:shutdown(Connection).

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.
