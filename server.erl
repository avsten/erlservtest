-module(server).
-export([start_server/0]).
-define(PortUse,5000). %%Номер порта
-vsn(1.0).

start_server() ->
	Pid = spawn_link(fun() ->
	{ok,LsnSocket} = gen_tcp:listen(?PortUse,[binary,{active,false}]), %%Инициализация сервера, использование сокета на прослушивание порта
	spawn(fun() -> acceptState(LsnSocket) end),
	timer:sleep(infinity)
	end),
	{ok, Pid}.
acceptState(LsnSocket) ->
	{ok, AcsSocket} = gen_tcp:accept(LsnSocket),
	spawn(fun() -> acceptState(LsnSocket) end), %%Инициализация обработчика
	handler(AcsSocket).
handler(AcsSocket) -> 				%%Тело обработчика
	inet:setopts(AcsSocket,[{active,once}]),
	receive
		{tcp,AcsSocket,<<"quit">>} -> %%Команда закрытия сокета
		gen_tcp:close(AcsSocket);
		{tcp,AcsSocket,<<"cube=",Number/binary>>} ->
		VarN = list_to_integer(binary_to_list(Number)),
		Res = VarN * VarN * VarN,
		gen_tcp:send(AcsSocket,"Result: "++list_to_binary(integer_to_list(Res))),
   		handler(AcsSocket);
		{tcp,AcsSocket,Msg} -> %%Блок ветвления выполняет код в зависимости от полученного сообщения (Msg)
		if
			(Msg =:= <<"Hello">>) ->
   			gen_tcp:send(AcsSocket,"Hello from Test Erlang server"),
   			handler(AcsSocket);
   			(Msg =:= <<"ServerStop">>) ->
   			gen_tcp:send(AcsSocket,"Server stopped!");
   			true ->
   			gen_tcp:send(AcsSocket,"Server response: Unknown request!"),
   			handler(AcsSocket)
   		end,
		handler(AcsSocket)
end.
