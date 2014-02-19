-module(proc_SUITE).

-include_lib("eunit/include/eunit.hrl").
-include_lib("common_test/include/ct.hrl").

-compile(export_all).

%%%=============================================================================
%%% common_test callbacks
%%%=============================================================================

all() -> [
          new,
          exec,
          async_exec,
          crash
         ].

suite() -> [{timetrap, {seconds, 5}}].

init_per_suite(Conf) ->
    ok = application:start(proc),
    Conf.

end_per_suite(_Conf) ->
    ok = application:stop(proc),
    ok.


init_per_testcase(_Module, Conf) ->
    Conf.

end_per_testcase(_Module, _Conf) ->
    ok.

%%%=============================================================================
%%% Tests
%%%=============================================================================

new(_Conf) ->
    P1 = proc:new(),
    P2 = proc:new(),
    proc:stop(P1),
    proc:stop(P2).


exec(_Conf) ->
    P1 = proc:new(),
    ?assertMatch(arg1, proc:exec(P1, {?MODULE, echo, [arg1]})),
    ?assertMatch(ok, proc:exec(P1, {timer, sleep, [20]}, 500)),
    ?assertMatch({error, timeout}, proc:exec(P1, {timer, sleep, [500]}, 20)),
    proc:stop(P1),
    ok.


async_exec(_Conf) ->
    P1 = proc:new(),
    Ref = proc:async_exec(P1, {?MODULE, echo, [arg1]}),
    ?assertMatch(arg1, proc:async_collect(Ref, 100)),

    Ref2 = proc:async_exec(P1, {timer, sleep, [500]}),
    ?assertMatch({error, timeout}, proc:async_collect(Ref2, 10)),
    timer:sleep(500),
    ?assertMatch(ok, proc:async_collect(Ref2, 10)),
    proc:stop(P1).


crash(_Conf) ->
    P1 = proc:new(),
    try
        proc:exec(P1, {timer, sleop, [20]})
    catch
        error:{undef,[{timer,sleop,[20],[]}, _]} ->
            ok
    end,
    ?assertMatch(ok, proc:exec(P1, {timer, sleep, [2]}, 500)),
    ok.


%%%=============================================================================
%%% Internal functions
%%%=============================================================================

echo(Arg) ->
    Arg.