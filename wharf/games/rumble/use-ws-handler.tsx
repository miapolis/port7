import React from "react";
import { WebSocketContext } from "@port7/modules/ws/ws-provider";
import { useRumbleStore } from "./use-rumble-store";
import { GameMilestone, LobbyMilestone, Tile } from "@port7/dock/lib/games/rumble";

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
              (milestone.tiles as any[]).map((t: any) => [t.id, t])
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
        useRumbleStore.getState().updateTile(data as Tile)
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
