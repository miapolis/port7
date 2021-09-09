import React from "react";
import { Peer } from "@port7/dock/lib/games/rumble/interfaces";
import { Button } from "@port7/ui";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "./use-rumble-store";

export interface JoinTableProps {
  peers: Peer[];
  isJoined: boolean;
  onJoinClick?: () => void;
}

export const JoinTable: React.FC<JoinTableProps> = ({ peers, isJoined, onJoinClick }) => {
  const conn = useConn();
  const [innerPeers, setInnerPeers] = React.useState<Peer[]>(peers);

  // Main WS event handler for peers
  React.useEffect(() => {
    if (!conn) return;

    conn.addListener("game_remove_peer", ({ data }: any) => {
      useRumbleStore.getState().removeJoinedPeer(data.id);
    });
    conn.addListener("peer_joined_round", ({ data }: any) => {
      console.log("happened");
      useRumbleStore.getState().addJoinedPeer(data.id, data.nickname);

      setInnerPeers([...innerPeers, {id: data.id, nickname: data.nickname, isDisconnected: false}])
    });
    conn.addListener("peer_left_round", ({ data }: any) => {
      useRumbleStore.getState().removeJoinedPeer(data.id);
    });
  }, [conn]);

  return (
    <div>
      <div className="w-96 h-96 bg-primary-700 rounded-full flex items-center justify-center flex-col shadow-xl">
        <div className="text-primary-100 text-2xl">No one is here yet</div>
        <div className="text-primary-200 text-xl mb-4">
          Click the join button below
        </div>
        <Button color="secondary" padding="large" onClick={onJoinClick}>
          JOIN ROUND
        </Button>
        {
          innerPeers.map((peer) => (
            <div key={peer.id}>{peer.nickname}</div>
          ))
        }
      </div>
    </div>
  );
};
