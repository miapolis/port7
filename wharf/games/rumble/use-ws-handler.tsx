import React from "react";
import { WebSocketContext } from "@port7/modules/ws/ws-provider";
import { useRumbleStore } from "./use-rumble-store";
import {
  GameMilestone,
  LobbyMilestone,
  Tile,
  TileObject,
  Group,
} from "@port7/dock/lib/games/rumble";

export const useWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const setMilestone = (milestone: any, landing = false) => {
      switch (milestone.state) {
        case "lobby":
          const lobby: LobbyMilestone = {
            state: milestone.state,
            startTime: milestone.startTime,
          };

          if (!landing) useRumbleStore.getState().setJoinedPeers([]);
          useRumbleStore.getState().setMilestone(lobby);
          break;
        case "game":
          const game: GameMilestone = {
            state: milestone.state,
            currentTurn: milestone.currentTurn,
            tiles: new Map(
              (milestone.tiles as TileObject[]).map((t) => [
                t.id,
                {
                  id: t.id,
                  x: t.x,
                  y: t.y,
                  groupId: t.groupId,
                  lockedX: undefined,
                  lockedY: undefined,
                  snapSide: undefined,
                  isDragging: false,
                  isSnapping: false,
                  isServerMoving: false,
                },
              ])
            ),
            groups: new Map(
              (milestone.groups as Group[]).map((g) => [g.id, g])
            ),
          };
          useRumbleStore.getState().setMilestone(game);
          break;
      }
    };

    const unsubs = [
      conn.addListener("landing", ({ data }: any) => {
        const filtered = data.peers.filter((x: any) => x.isJoined === true);
        useRumbleStore.getState().setJoinedPeers(filtered);
        useRumbleStore.getState().setServerNow(data.milestone.serverNow);

        setMilestone(data.milestone, true);
        useRumbleStore.getState().doLanding();
      }),
      conn.addListener("peer_joined_round", ({ data }: any) => {
        useRumbleStore.getState().addJoinedPeer(data.id, data.nickname);
      }),
      conn.addListener("game_remove_peer", ({ data }: any) => {
        useRumbleStore.getState().removeJoinedPeer(data.id);
      }),
      conn.addListener("peer_left_round", ({ data }: any) => {
        useRumbleStore.getState().removeJoinedPeer(data.id);
      }),
      conn.addListener("remove_peer", ({ data }: any) => {
        useRumbleStore.getState().removeJoinedPeer(data.id);
      }),
      conn.addListener("round_starting", ({ data }: any) => {
        useRumbleStore.getState().setServerNow(data.now);
        useRumbleStore.getState().setStartTimestamp(data.in);
      }),
      conn.addListener("cancel_start_round", ({}: any) => {
        useRumbleStore.getState().setStartTimestamp(undefined);
      }),
      conn.addListener("set_milestone", ({ data }: any) => {
        setMilestone(data);
      }),
      conn.addListener("tile_moved", ({ data }: any) => {
        useRumbleStore.getState().updateTile(data as Tile);
      }),
      conn.addListener("server_move", ({ data }: any) => {
        data.tiles.forEach((tile: Tile) => {
          useRumbleStore
            .getState()
            .updateTile({ ...tile, isServerMoving: true });
        });

        setTimeout(() => {
          data.tiles.forEach((tile: Tile) => {
            useRumbleStore
              .getState()
              .updateTile({ ...tile, isServerMoving: false });
          });
        }, 100);
      }),
      conn.addListener("tile_snapped", ({ data }: any) => {
        const milestone = useRumbleStore.getState().milestone as GameMilestone;
        const tiles = milestone.tiles;

        const current = tiles.get(data.id) as TileObject;
        const snapToTile = tiles.get(data.snapTo) as TileObject;
        const group = data.group as Group;

        group.children.forEach((id) => {
          const found = tiles.get(id) as TileObject;
          found.groupId = group.id;
          useRumbleStore.getState().updateTile(found);
        });

        useRumbleStore.getState().updateGroup({
          ...group,
        });

        const updated = {
          ...current,
          x: data.snapSide == 1 ? snapToTile.x + 100 : snapToTile.x - 100,
          y: snapToTile.y,
          isSnapping: true,
        };

        useRumbleStore.getState().updateTile(updated);

        setTimeout(() => {
          useRumbleStore
            .getState()
            .updateTile({ ...updated, isSnapping: false });
        }, 100);
      }),
      conn.addListener("delete_group", ({ data }: any) => {
        const milestone = useRumbleStore.getState().milestone as GameMilestone;
        const group = milestone.groups.get(data.id) as Group;

        group.children.forEach((id) => {
          const tile = milestone.tiles.get(id) as TileObject;
          useRumbleStore.getState().updateTile({ ...tile, groupId: null });
        });

        useRumbleStore.getState().deleteGroup(data.id);
      }),
      conn.addListener("update_group", ({ data }: any) => {
        const milestone = useRumbleStore.getState().milestone as GameMilestone;
        const group = data.group;

        group.children.forEach((id: any) => {
          const tile = milestone.tiles.get(id) as TileObject;
          useRumbleStore.getState().updateTile({ ...tile, groupId: group.id });
        });

        if (data.remove) {
          const tile = milestone.tiles.get(data.remove);
          useRumbleStore.getState().updateTile({ ...tile, groupId: null });
        }
        if (data.strict) {
          const found = milestone.groups.get(group.id)!;
          found.children.forEach((child) => {
            if (!group.children.includes(child)) {
              const tile = milestone.tiles.get(child) as TileObject;
              useRumbleStore.getState().updateTile({ ...tile, groupId: null });
            }
          });
        }

        useRumbleStore.getState().updateGroup(group);
      }),
      conn.addListener("mass_update_groups", ({ data }: any) => {
        const milestone = useRumbleStore.getState().milestone as GameMilestone;
        const groups = data.groups;

        groups.forEach((group: any) => {
          const localGroup = milestone.groups.get(group.id);
          const children: number[] = group.children;

          children.forEach((child) => {
            const tile = milestone.tiles.get(child)!;
            useRumbleStore
              .getState()
              .updateTile({ ...tile, groupId: group.id });
          });

          if (localGroup) {
            localGroup.children.forEach((child) => {
              if (!group.children.includes(child)) {
                const tile = milestone.tiles.get(child) as TileObject;
                useRumbleStore
                  .getState()
                  .updateTile({ ...tile, groupId: null });
              }
            });
          }

          useRumbleStore.getState().updateGroup(group);
        });
      }),
    ];

    return () => {
      unsubs.forEach((u) => u());
    };
  }, [conn]);
};

export const WsHandlerProvider: React.FC = ({ children }) => {
  useWsHandler();
  return <>{children}</>;
};
