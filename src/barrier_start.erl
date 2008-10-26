%%% Copyright (C) 2005-2008 Wager Labs, SA

-module(barrier_start).

-export([start/3, barrier_start/3]).

-include("common.hrl").
-include("game.hrl").
-include("texas.hrl").
-include("pp.hrl").

-define(DELAY, 15000).

start(Game, Ctx, [Barrier]) ->
    process_flag(trap_exit, true),
    link(Barrier),
    Game1 = Game#game{ barrier = Barrier },
    Game2 = g:restart_timer(Game1, ?DELAY),
    %% reset call amount
    Ctx1 = Ctx#texas{ call = 0 },    
    {next, barrier_start, Game2, Ctx1}.

barrier_start(Game, Ctx, {timeout, _, _}) ->
    Ready = g:get_seats(Game, ?PS_READY),
    ReqCount = Game#game.required_player_count,
    Barrier = Game#game.barrier,
    Start = (length(Ready) >= ReqCount),
    Game1 = if
                Start ->
                    barrier:bump(Barrier),
                    g:cancel_timer(Game);
                true ->
                    g:notify_cancel_game(Game),
                    g:restart_timer(Game, ?DELAY)
            end,
    {continue, Game1, Ctx};

barrier_start(Game, Ctx, {'EXIT', Barrier, _})
  when Barrier == Game#game.barrier ->
    g:notify_start(Game),
    {stop, Game, Ctx};

barrier_start(Game, Ctx, R = #join{}) ->
    Game1 = g:join(Game, R, ?PS_PLAY),
    {continue, Game1, Ctx};

barrier_start(Game, Ctx, R = #leave{}) ->
    Game1 = g:leave(Game, R, ?PS_ANY),
    {continue, Game1, Ctx};

barrier_start(Game, Ctx, _) ->
    {skip, Game, Ctx}.

