import React from "react";
import { WebSocketContext } from "@port7/modules/ws/ws-provider";
import { useRumbleStore } from "./use-rumble-store";

export const useWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const unsubs = [
      conn.addListener("landing", ({ data }: any) => {
        const filtered = data.peers.filter((x: any) => x.isJoined === true);
        useRumbleStore.getState().setJoinedPeers(filtered);

        useRumbleStore.getState().setServerNow(data.milestone.serverNow);
        if (data.milestone.startTime) {
          useRumbleStore.getState().setStartTimestamp(data.milestone.startTime);
        }

        useRumbleStore.getState().doLanding();
      }),
      conn.addListener("round_starting", ({ data }: any) => {
        useRumbleStore.getState().setServerNow(data.now);
        useRumbleStore.getState().setStartTimestamp(data.in);
      }),
      conn.addListener("cancel_start_round", ({}: any) => {
        useRumbleStore.getState().setStartTimestamp(undefined);
      }),
      conn.addListener("remove_peer", ({ data }: any) => {
        useRumbleStore.getState().removeJoinedPeer(data.id);
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
