# Erlang library for [Deribit API](https://docs.deribit.com/)

# !DEPRECATED!

### V1 API will be shut down beginning October in favor of the [Deribit V2 API](https://docs.deribit.com/v2/#deribit-api-v2-0-0)
### Please make sure to update your codebase to prepare for the transition.
### You can refer to the V2 API clients available [here](https://github.com/deribit/deribit-api-clients/)

# !DEPRECATED!

## Description

The [Deribit API](https://docs.deribit.com/) is available in this package.

This package contains module:
* `deribit_api` - connects with [Deribit API](https://docs.deribit.com/) through REST or websocket

### Compile 
```
rebar3 compile
```

### Example

```
{ok, Connection} = deribit_api:open("Key", "Secret", websocket).
Result = deribit_api:getlasttrades(Pid, #{ instrument => "BTC-7APR17"} ).
deribit_api:getlasttrades(Connection, #{ instrument => "BTC-7APR17"}, {async, fun(R) -> io:format("Result: ~p~n", [R]) end}).

Ref = deribit_api:getlasttrades(Connection, #{ instrument => "BTC-7APR17"}, async),
receive 
  {Connection, {Ref, Status, Data}} -> io:format("Status: ~p, Data: ~p~n", [Status, Data]) 
end.
```

## API - Client `deribit_api`

### Initializer

* `open()`  
  `open(Options)`  
  `open(AccessKey, AccessSecret)`  
  `open(AccessKey, AccessSecret, Option)`

  Creates new `Pid` - connection identifier, prepares connection with server. If `Option` is not provided, http connection is used to communicate with `deribit.com` server, 

  **Params map values:**

  | Name           | Type            | Definition                                                 |
  |----------------|-----------------|------------------------------------------------------------|
  | `AccessKey`    | `string`        | Optional, Access Key needed to access Private functions    |
  | `AccessSecret` | `string`        | Optional, Access Secret needed to access Private functions |
  | `Options`      | `atom | string` | Optional: <ul><li>if undefined or `http` - connection in HTTP over SSL is opened to host `deribit.com`</li><li>`websocket` - websocket connection over SSL is opened to host `deribit.com`</li><li>url - full URL to server with scheme (`http`, `https`, `ws`, `wss`), host and optional port number</li></ul> |

### Methods

Parameters in all methods: 

| Key        | Definition                                                 |
|------------|------------------------------------------------------------|
| `Pid`      | Required, connection identifier, from `deribit_api:open`   |
| `Params`   | Required map in some methods, see description of each      |
| `Options`  | Optional, see description below                            |

#### Options

All methods accept optional `Options` list as last parameter. Allowed values:

* not provided - method returns:
  * `{error, Message}` - when error occurred, `Message` is error message
  * `{ok, Result}` - when result was received, `Result` is resonse
* `[async]` - result is sent to calling process and `Ref` - request identifier is returned. Sent message format: `{Pid, {Ref, ok | error, Data = any()}`
* `{async, fun:1}` - when result is received `fun` is called. 

### List of methods:

* `index(Connection)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#index), public  
  `index(Connection, Options)`

  Get price index, BTC-USD rates.

* `getcurrencies(Connection)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#getcurrencies), public  
  `getcurrencies(Connection, Options)`

  Get all supported currencies.

* `getorderbook(Connection, Instrument)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#getorderbook), public  
  `getorderbook(Connection, Instrument, Options)`

  Retrieve the orderbook for a given instrument.

  **Parameters:**

  | Key          | Type                  | Decription                                                 |
  |--------------|-----------------------|------------------------------------------------------------|
  | `Instrument` | `string() | binary()` | Required, instrument name                                  |

* `getlasttrades(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#getlasttrades), public    
  `getlasttrades(Connection, Params, Options)`  

  Retrieve the latest trades that have occured for a specific instrument.

  **Params map values:**

  | Key          | Type                    | Decription                                                                    |
  |--------------|-------------------------|-------------------------------------------------------------------------------|
  | `Instrument` | `string() | binary()`   | Required, instrument name                                                     |
  | `count`      | `integer()`             | Optional, count of trades returned (limitation: max. count is 100)            |
  | `since`      | `integer()`             | Optional, “since” trade id, the server returns trades newer than that “since” |

* `getsummary(Connection, Instrument)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#getsummary), public  
  `getsummary(Connection, Instrument, Options)`

  Retrieve the summary info such as Open Interest, 24H Volume etc for a specific instrument.

  **Parameters:**

  | Key          | Type                  | Decription                                                 |
  |--------------|-----------------------|------------------------------------------------------------|
  | `Instrument` | `string() | binary()` | Required, instrument name                                  |

* `account(Connection)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#account), Private  
  `account(Connection, Options)`

  Get user account summary.

* `buy(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#buy), private  
  `buy(Connection, Params, Options)`  

  Place a buy order in an instrument.

  **Params map values:**

  | Key          | Type                             | Decription                                                                        |
  |--------------|----------------------------------|-----------------------------------------------------------------------------------|
  | `Instrument` | `string() | binary()`            | Required, instrument name                                                         |
  | `Quantity`   | `integer() | float() | string()` | Required, quantity, in contracts ($10 per contract for futures, ฿1 — for options) |
  | `Price`      | `integer() | float() | string()` | Required, USD for futures, BTC for options                                        |
  | `PostOnly`   | `boolean()`                      | Optional, if true then the order will be POST ONLY                                |
  | `Label`      | `string() | binary()`            | Optional, user defined maximum 4-char label for the order                         |

* `sell(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#sell), private  
  `sell(Connection, Params, Options)`  

  Place a sell order in an instrument.

  **Params map values:**

  | Key         | Type       | Decription                                                                        |
  |--------------|------------|-----------------------------------------------------------------------------------|
  | `Instrument` | `string`   | Required, instrument name                                                         |
  | `Quantity`   | `integer`  | Required, quantity, in contracts ($10 per contract for futures, ฿1 — for options) |
  | `Price`      | `float`    | Required, USD for futures, BTC for options                                        |
  | `PostOnly`   | `boolean`  | Optional, if true then the order will be POST ONLY                                |
  | `Label`      | `string`   | Optional, user defined maximum 4-char label for the order                         |

* `edit(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#edit)  
  `edit(Connection, Params, Options)`

  Edit price and/or quantity of the own order. (Authorization is required).

  **Params map values:**

  | Key          | Type                             | Decription                                                                        |
  |--------------|----------------------------------|-----------------------------------------------------------------------------------|
  | `OrderId`    | `integer()`                      | Required, ID of the order returned by "sell" or "buy" request                     |
  | `Quantity`   | `integer() | float() | string()` | Required, quantity, in contracts ($10 per contract for futures, ฿1 — for options) |
  | `Price`      | `integer() | float() | string()` | Required, USD for futures, BTC for options                                        |

* `cancel(Connection, OrderId)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#cancel), private  
  `cancel(Connection, OrderId, Options)`

  Cancel own order by id.

  **Parameters:**

  | Key          | Type        | Decription                                                                        |
  |--------------|------------ |-----------------------------------------------------------------------------------|
  | `OrderId`    | `integer()` | Required, ID of the order returned by "sell" or "buy" request                     |

* `cancelall(Connection, Type)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#cancelall)  
  `cancelall(Connection, Type, Options)`

  Cancel all own futures, or all options, or all.

  **Parameters:**

  | Key          | Type                      | Decription                                                                    |
  |--------------|---------------------------|-------------------------------------------------------------------------------|
  | `Type`       | `all | futures | options` | Optional, type of instruments to cancel, allowed: "all", "futures", "options" |

* `getopenorders(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#getopenorders), private  
  `getopenorders(Connection, Params, Options)`  

  Retrieve open orders.

  **Params map values:**

  | Key          | Type                  | Description                                                           |
  |--------------|-----------------------|-----------------------------------------------------------------------|
  | `Instrument` | `string() | binary()` | Optional, instrument name, use if want orders for specific instrument |
  | `OrderId`    | `integer()`           | Optional, order id                                                    |

* `positions(Connection)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#positions), private  
  `positions(Connection, Options)`

  Retreive positions.

* `orderhistory(Connection)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#orderhistory), private  
  `orderhistory(Connection, Count)`  
  `orderhistory(Connection, Count, Options)`

  Get history.

  **Parameters**

  | Key        | Type        | Description                                                                    |
  |------------|-------------|--------------------------------------------------------------------------------|
  | `Count`    | `integer()` | Optional, number of requested records, if not provided all records is returned |

* `tradehistory(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#tradehistory), private  
  `tradehistory(Connection, Params, Options)`  

  Get private trade history of the account. (Authorization is required). The result is ordered by trade identifiers (trade id-s).

  **Params map values:**

  | Key            | Type       | Description                                                                                        |
  |----------------|------------|----------------------------------------------------------------------------------------------------|
  | `Count`        | `integer()`| Optional, number of results to fetch.                                                              |
  | `Instrument`   | `string() | binary() | all | futures | options`| Required, name of instrument, also aliases “all”, “futures”, “options” are allowed |
  | `StartTradeId` | `integer()`| Optional, number of requested records                                                              |


### Additional methods available only when connected through websocket

* `subscribe(Connection, Params)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#orderhistory), private  
  `subscribe(Connection, Params, Options)`

  Subscribe to notifications. Notifications are send to calling process.

  **Params map values:**

  | Key      | Type     | Description                                                                                 |
  |----------|---------|--------------------------------------------------------------------------------------------|
  | `Count`  | `list(string()) | [all] | [futures] | [options] | [index]` | Required, list of instrument names, also aliases “all”, “futures”, “options” are allowed.  |
  | `Events` | `list(order_book | trade | user_order)` | Required, events to be reported                                                            |

* `unsubscribe(Connection)` - [Doc](https://docs.deribit.com/rpc-endpoints.html#unsubscribe), private

  Unsubscribe notifications.
