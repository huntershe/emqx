%% Copyright (c) 2018 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_router_sup).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Helper = #{id       => helper,
               start    => {emqx_router_helper, start_link, []},
               restart  => permanent,
               shutdown => 5000,
               type     => worker,
               modules  => [emqx_router_helper]},
    Replicator = #{id       => replicator,
                   start    => {emqx_route_replicator, start_link, []},
                   restart  => permanent,
                   shutdown => 5000,
                   type     => worker,
                   modules  => [emqx_route_replicator]},
    %% Router pool
    RouterPool = emqx_pool_sup:spec(emqx_router_pool,
                                    [router, hash, emqx_vm:schedulers(),
                                     {emqx_router, start_link, []}]),
    {ok, {{one_for_all, 0, 1}, [Helper, Replicator, RouterPool]}}.

