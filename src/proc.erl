%% Copyright 2014, Miriam Pena <miriam.pena@gmail.com>
%%
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%%
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
%%
-module(proc).

%% Api
-export([new/0,
         exec/2,
         exec/3,
         async_exec/2,
         async_collect/2,
         stop/1]).

%%==============================================================================
%% Api
%%==============================================================================

%% @doc: Creates a new process.
-spec new() -> Proc :: pid().
new() ->
    process_flag(trap_exit, true),
    Parent = self(),
    Proc = spawn_link(fun() ->
                              process_flag(trap_exit, true),
                              proc_loop(Parent)
                      end),
    case request(Proc, alive, 100) of
        true ->
            Proc;
        {error, Reason} ->
            {error, Reason}
    end.


%% @doc: Syncronous request.
-spec exec(Proc :: pid(), MFA :: tuple()) -> Result :: term().
exec(Proc, MFA) ->
    exec(Proc, MFA, 5000).


-spec exec(Proc :: pid(), MFA :: tuple(), Timeout :: integer()) ->
                  Result :: term().
exec(Proc, MFA, Timeout) ->
    request(Proc, MFA, Timeout).


%% @doc: Asyncronus request.
%%  Returns a reference that is used to collect the response.
%%  with function async_collect(Ref)
-spec async_exec(Proc :: pid(), MFA :: tuple()) -> RRef :: term().
async_exec(Proc, MFA) ->
    async_request(Proc, MFA).


%% @doc: Collects the response of an asyncronous request.
%% If the request has launched an exception
%% async_collect will also crash
-spec async_collect(RRef :: term(), Timeout :: integer()) ->
                           Response :: term().
async_collect({Ref, Proc}, Timeout) ->
    receive
        {'EXIT', Proc, _} = Reason->
            {error, Reason};
        {Ref, {exception, Type, Cause}} ->
            apply(erlang, Type, [Cause]);
        {'DOWN', _Ref, _, _, _} ->
            {error, no_proc};
        {Ref, Result} ->
            Result
    after Timeout ->
            {error, timeout}
    end.


%% @doc: Stops the process
-spec stop(Proc :: pid()) -> ok | {error, timeout}.
stop(Proc) ->
    MRef = erlang:monitor(process, Proc),
    Proc ! stop,
    receive
        {'DOWN', MRef, _, _, _} ->
            ok
    after 10000 ->
            {error, timeout}
    end.


%%==============================================================================
%% Internal functions
%%==============================================================================

async_request(Proc, What) ->
    Ref = erlang:monitor(process, Proc),
    Parent = self(),
    Proc ! {Parent, Ref, What},
    {Ref, Proc}.


request(Proc, What, Timeout) ->
    Ref = async_request(Proc, What),
    async_collect(Ref, Timeout).


proc_loop(Parent) ->
    receive
        {Parent2, Ref, alive} ->
            Parent2 ! {Ref, true},
            proc_loop(Parent);
        stop ->
            ok;
        {Parent2, Ref, {M, F, Arg}} ->
            Response = try
                           erlang:apply(M, F, Arg)
                       catch
                           E:R ->
                               Stack = erlang:get_stacktrace(),
                               {exception, E, {R, Stack}}
                       end,
            Parent2 ! {Ref, Response},
            proc_loop(Parent);
        {'EXIT', Parent, _} ->
            ok
    end.
