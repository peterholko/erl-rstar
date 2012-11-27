-module(rstar_delete_test).
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

-include("../include/rstar.hrl").

main_test_() ->
    {foreach,
     fun setup/0,
     fun cleanup/1,
     [
      fun find_leaf_exists_test/1,
      fun find_leaf_not_exists_test/1,
      fun collect_records_leaf_test/1,
      fun collect_records_one_level_test/1,
      fun delete_recursive_leaf_no_undeflow_test/1,
      fun delete_recursive_leaf_root_underflow_test/1,
      fun delete_recursive_leaf_underflow_test/1,
      fun delete_recursive_child_underflow_test/1,
      fun delete_recursive_child_no_underflow_test/1,
      fun delete_recursive_parent_underflow_test/1,
      fun delete_recursive_parent_root_underflow_test/1,
      fun delete_internal_no_underflow_test/1,
      fun delete_internal_single_child_test/1,
      fun delete_internal_reinsert_test/1,
      fun delete_not_found_test/1,
      fun delete_found_test/1
     ]}.

setup() -> ok.
cleanup(_) -> ok.

find_leaf_exists_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            L3 = #geometry{dimensions=2, mbr=[{2, 2}, {2, 2}], value=#leaf{}},
            L4 = #geometry{dimensions=2, mbr=[{-1, -1}, {-1, -1}], value=#leaf{}},
            NGeo = rstar_geometry:bounding_box([L4, L3, L2, L1]),
            N = NGeo#geometry{value=#leaf{entries=[L4, L3, L2, L1]}},
            Root = NGeo#geometry{value=#node{children=[N]}},

            ?assertEqual({found, [Root, N]}, rstar_delete:find_leaf(Root, L1))
        end
    ).

find_leaf_not_exists_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            L3 = #geometry{dimensions=2, mbr=[{2, 2}, {2, 2}], value=#leaf{}},
            L4 = #geometry{dimensions=2, mbr=[{-1, -1}, {-1, -1}], value=#leaf{}},
            NGeo = rstar_geometry:bounding_box([L4, L3, L2, L1]),
            N = NGeo#geometry{value=#leaf{entries=[L4, L3, L2, L1]}},
            Root = NGeo#geometry{value=#node{children=[N]}},

            G = #geometry{dimensions=2, mbr=[{0.5, 0.5}, {0.5, 0.5}], value=#leaf{}},

            ?assertEqual(not_found, rstar_delete:find_leaf(Root, G))
        end
    ).

collect_records_leaf_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            L3 = #geometry{dimensions=2, mbr=[{2, 2}, {2, 2}], value=#leaf{}},
            L4 = #geometry{dimensions=2, mbr=[{-1, -1}, {-1, -1}], value=#leaf{}},
            NGeo = rstar_geometry:bounding_box([L4, L3, L2, L1]),
            N = NGeo#geometry{value=#leaf{entries=[L4, L3, L2, L1]}},

            ?assertEqual([L4, L3, L2, L1], rstar_delete:collect_records(N))
        end
    ).

collect_records_one_level_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            L3 = #geometry{dimensions=2, mbr=[{2, 2}, {2, 2}], value=#leaf{}},
            L4 = #geometry{dimensions=2, mbr=[{-1, -1}, {-1, -1}], value=#leaf{}},

            N1Geo = rstar_geometry:bounding_box([L4, L3]),
            N1 = N1Geo#geometry{value=#leaf{entries=[L3, L4]}},

            N2Geo = rstar_geometry:bounding_box([L2, L1]),
            N2 = N2Geo#geometry{value=#leaf{entries=[L1, L2]}},

            Root = N1Geo#geometry{value=#node{children=[N1, N2]}},
            ?assertEqual([L1, L2, L3, L4], rstar_delete:collect_records(Root))
        end
    ).

delete_recursive_leaf_no_undeflow_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            L3 = #geometry{dimensions=2, mbr=[{2, 2}, {2, 2}], value=#leaf{}},
            L4 = #geometry{dimensions=2, mbr=[{-1, -1}, {-1, -1}], value=#leaf{}},
            NGeo = rstar_geometry:bounding_box([L4, L3, L2, L1]),
            N = NGeo#geometry{value=#leaf{entries=[L4, L3, L2, L1]}},
            Params1 = #rt_params{min=2, max=5, reinsert=2},

            NewGeo = rstar_geometry:bounding_box([L3, L2, L1]),
            ExpectedNode = NewGeo#geometry{value=#leaf{entries=[L3, L2, L1]}},

            Expected = {ExpectedNode, []},
            ?assertEqual(Expected, rstar_delete:delete_recursive(Params1, N, [N], L4))
        end
    ).

delete_recursive_leaf_root_underflow_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            NGeo = rstar_geometry:bounding_box([L2, L1]),
            N = NGeo#geometry{value=#leaf{entries=[L2, L1]}},
            Params1 = #rt_params{min=2, max=5, reinsert=2},

            NewGeo = rstar_geometry:bounding_box([L1]),
            ExpectedNode = NewGeo#geometry{value=#leaf{entries=[L1]}},

            % Root cannot underflow
            Expected = {ExpectedNode, []},
            ?assertEqual(Expected, rstar_delete:delete_recursive(Params1, N, [N], L2))
        end
    ).

delete_recursive_leaf_underflow_test(_) ->
    ?_test(
        begin
            L1 = #geometry{dimensions=2, mbr=[{1,1}, {1,1}], value=#leaf{}},
            L2 = #geometry{dimensions=2, mbr=[{0,0}, {0,0}], value=#leaf{}},
            NGeo = rstar_geometry:bounding_box([L2, L1]),
            N = NGeo#geometry{value=#leaf{entries=[L2, L1]}},
            Params1 = #rt_params{min=2, max=5, reinsert=2},

            % Should underflow
            Expected = {undefined, [L1]},
            ?assertEqual(Expected, rstar_delete:delete_recursive(Params1, L1, [N], L2))
        end
    ).

delete_recursive_child_underflow_test(_) -> ok.
delete_recursive_child_no_underflow_test(_) -> ok.
delete_recursive_parent_underflow_test(_) -> ok.
delete_recursive_parent_root_underflow_test(_) -> ok.
delete_internal_no_underflow_test(_) -> ok.
delete_internal_single_child_test(_) -> ok.
delete_internal_reinsert_test(_) -> ok.
delete_not_found_test(_) -> ok.
delete_found_test(_) -> ok.

