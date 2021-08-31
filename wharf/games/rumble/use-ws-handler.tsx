import React from "react";
import { WebSocketContext } from "@port7/modules/ws/ws-provider";
import { useRumbleStore } from "./use-rumble-store";
import { Peer } from "@port7/dock/lib/games/rumble";

export const useWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const unsubs = [
      conn.addListener("landing", ({ data }: any) => {
        useRumbleStore
          .getState()
          .setJoinedPeers(
            data.peers.filter((x: any) => x.isJoined === true) || []
          );

        useRumbleStore.getState().setServerNow(data.milestone.serverNow);
        if (data.milestone.startTime) {
          useRumbleStore.getState().setStartTimestamp(data.milestone.startTime);
        }

        useRumbleStore.getState().doLanding();
      }),
      conn.addListener("game_remove_peer", ({ data }: any) => {
        useRumbleStore.getState().removeJoinedPeer(data.id);
      }),
      conn.addListener("peer_joined_round", ({ data }: any) => {
        useRumbleStore.getState().addJoinedPeer(data.id, data.nickname);
      }),
      conn.addListener("peer_left_round", ({ data }: any) => {
        useRumbleStore.getState().removeJoinedPeer(data.id);
      }),
      conn.addListener("round_starting", ({ data }: any) => {
        useRumbleStore.getState().setServerNow(data.now);
        useRumbleStore.getState().setStartTimestamp(data.in);
      }),
      conn.addListener("cancel_start_round", ({}: any) => {
        useRumbleStore.getState().setStartTimestamp(undefined);
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
