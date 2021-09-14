import React from "react";
import { WebSocketContext } from "@port7/modules/ws/ws-provider";
import { useRumbleStore } from "./use-rumble-store";
import { GameMilestone, LobbyMilestone } from "@port7/dock/lib/games/rumble";

export const useWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const unsubs = [
      conn.addListener("landing", ({ data }: any) => {
        const filtered = data.peers.filter((x: any) => x.isJoined === true);
        useRumbleStore.getState().setJoinedPeers(filtered);
        useRumbleStore.getState().setServerNow(data.milestone.serverNow);

        switch (data.milestone.state) {
          case "lobby":
            const lobby: LobbyMilestone = {
              state: data.milestone.state,
              startTime: data.milestone.startTime,
            };
            useRumbleStore.getState().setMilestone(lobby);
            break;
          case "game":
            const game: GameMilestone = {
              state: data.milestone,
              currentTurn: data.milestone.currentTurn,
            };
            useRumbleStore.getState().setMilestone(game);
            break;
        }

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
        useRumbleStore.getState().setMilestone(data.state);
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
