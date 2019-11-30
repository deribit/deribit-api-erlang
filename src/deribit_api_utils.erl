-module(deribit_api_utils).

-export([
  to_string/1,
  generate_signature/4,
  to_binary/1,
  transform_map_keys_to_atom/1,
  request/3, request/4
]).

-define(TIMEOUT, 5000).

generate_signature(Key, Secret, Uri, Data) ->
  Tstamp = io_lib:format("~w", [os:system_time(milli_seconds)]),
  StartingData = #{
    "_" => Tstamp,
    "_ackey" => Key,
    "_acsec" => Secret,
    "_action" => Uri
  },
  AllData = maps:merge(StartingData, Data),

  ParamsString = deribit_api_utils:to_string(AllData),
  Hash = erlang:binary_to_list(base64:encode(crypto:hash(sha256, ParamsString))),
  lists:flatten([Key, ".", Tstamp, ".", Hash]).

to_binary(Data) when is_binary(Data) ->
  Data;
to_binary(Data) ->
  list_to_binary(Data).
  
transform_map_keys_to_atom(Map) ->
  lists:foldl(fun(Key, Acc) ->
    Val = maps:get(Key, Map),
    ValFun = fun 
                ValFun({array, El}) -> lists:map(fun(E) ->  ValFun(E) end, El);
                ValFun(El) when is_integer(El) -> erlang:list_to_binary(io_lib:format("~B", [El]));
                ValFun(El) when is_number(El) -> erlang:list_to_binary(io_lib:format("~.12f", [El]));
                ValFun(false) -> false;
                ValFun(true) -> true;
                ValFun(El) when is_atom(El) -> erlang:list_to_binary(erlang:atom_to_list(El));
                ValFun([]) -> <<"">>;
                ValFun(El) when is_list(El) -> erlang:list_to_binary(El);
                ValFun(El) -> El
              end,
    NewVal = ValFun(Val),
    case erlang:is_list(Key) of
      true ->
        maps:put(erlang:list_to_atom(Key), NewVal, Acc);
      false ->
        maps:put(Key, NewVal, Acc)
    end
  end, #{}, maps:keys(Map)).
  
to_string(List) when is_list(List) ->
  lists:flatten(lists:join("&", lists:map(fun(El) -> to_string(El) end, List)));
to_string(Map) when is_map(Map) ->
  Transformed = lists:foldl(fun(Key, Acc) ->
    Val = maps:get(Key, Map),
    case erlang:is_atom(Key) of
      true ->
        maps:put(erlang:atom_to_list(Key), Val, Acc);
      false ->
        maps:put(Key, Val, Acc)
    end
  end, #{}, maps:keys(Map)),
  to_string(maps:to_list(Transformed));
to_string({Key, {array, Val}}) ->
  to_string({Key, lists:concat(Val)});
to_string({Key, Val}) when is_atom(Key) ->
  to_string({erlang:atom_to_list(Key), Val});
to_string({Key, Val}) when is_integer(Val) ->
  to_string({Key, io_lib:format("~B", [Val])});
to_string({Key, Val}) when is_number(Val) ->
  to_string({Key, io_lib:format("~.12f", [Val])});
to_string({Key, Val}) ->
  io_lib:format("~s=~s", [Key, Val]).

request(Pid, Action, Data) ->
  request(Pid, Action, Data, []).
request(Pid, Action, Data, Options) ->
  case proplists:get_value(async, Options, false) of
    false ->
      Ref = gen_server:call(Pid, {request, Action, Data, self()}),
      receive
        {Pid, {Ref, Status, Message}} -> {Status, Message}
      after
        ?TIMEOUT -> {error, timeout}
      end;

    true ->
      gen_server:call(Pid, {request, Action, Data, self()});

    Fun when is_function(Fun) ->
      gen_server:call(Pid, {request, Action, Data, Fun}),
      ok;
    _ ->
      throw(wrong_options)
  end.