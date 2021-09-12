import React from "react";
import { Peer } from "@port7/dock/lib/games/rumble/interfaces";
import { Button } from "@port7/ui";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "./use-rumble-store";
import { PlayerSeat } from "./player-seat";

export interface JoinTableProps {
  isJoined: boolean;
  secondsToStart: number;
  onJoinClick?: () => void;
}

export const JoinTable: React.FC<JoinTableProps> = ({
  isJoined,
  secondsToStart,
  onJoinClick,
}) => {
  const conn = useConn();
  const joinedPeers = useRumbleStore().joinedPeers;
  const mainStatusRef = React.useRef<HTMLDivElement>(null);

  const [status, setStatus] = React.useState<string[]>(["", ""]);

  React.useEffect(() => {
    let newStatus;
    switch (joinedPeers.size) {
      case 0:
        newStatus = ["No one is here yet", "Click the join button below"];
        break;
      case 1:
        newStatus = [
          "Waiting for one more player",
          "Click the join button below",
        ];
        break;
      case 2:
      case 3:
        newStatus = [`Round starting in $s`, "Join before it's too late!"];
        break;
      default:
        newStatus = [`Round starting in $s`, "All seats are full"];
        break;
    }
    setStatus(newStatus);
  }, [joinedPeers.size]);

  // Main WS event handler for peers
  React.useEffect(() => {
    if (!conn) return;

    conn.addListener("game_remove_peer", ({ data }: any) => {
      useRumbleStore.getState().removeJoinedPeer(data.id);
      // setInnerPeers(innerPeers.filter((x) => x.id != data.id));
    });
    conn.addListener("peer_joined_round", ({ data }: any) => {
      // console.log("CURRENT STATE OF INNER PEERS", innerPeers);
      useRumbleStore.getState().addJoinedPeer(data.id, data.nickname);

      // console.log("EXISTING", innerPeers);
      // setInnerPeers([
      //   ...innerPeers,
      //   { id: data.id, nickname: data.nickname, isDisconnected: false },
      // ]);
    });
    conn.addListener("peer_left_round", ({ data }: any) => {
      useRumbleStore.getState().removeJoinedPeer(data.id);
      // setInnerPeers(new Array());
    });
  }, [conn]);

  return (
    <div>
      <div className="w-96 h-96 bg-primary-700 rounded-full flex items-center justify-center flex-col shadow-xl">
        <div className="text-primary-100 text-2xl" ref={mainStatusRef}>
          {status[0].replace("$", secondsToStart.toString())}
        </div>
        <div className="text-primary-200 text-xl mb-4">{status[1]}</div>
        <Button
          color={!isJoined ? "secondary" : "ternary"}
          padding={!isJoined ? "large" : "normal"}
          onClick={onJoinClick}
        >
          {!isJoined ? "JOIN ROUND" : "LEAVE ROUND"}
        </Button>
        {Array.from(useRumbleStore.getState().joinedPeers.values()).map(
          (peer, index) => (
            <PlayerSeat
              angle={index * -90}
              nickname={peer.nickname}
              key={peer.id}
            />
          )
        )}
      </div>
    </div>
  );
};
