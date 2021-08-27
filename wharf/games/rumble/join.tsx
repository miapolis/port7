import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "./use-rumble-store";
import { me } from "@port7/modules/room/use-room-store";

export const Join = () => {
  const conn = useConn();
  const state = useRumbleStore();
  const self = me();

  const [isJoined, setIsJoined] = React.useState(
    Array.from(state.joinedPeers.values() || [])
      .map((x) => x.id)
      .includes(self.id)
  );

  const joinButtonClicked = async () => {
    if (!isJoined) {
      conn?.sendCast("rumble:join_round", {});
    } else {
      conn?.sendCast("rumble:leave_round", {});
    }
    setIsJoined(!isJoined);
  };

  return (
    <div className="flex flex-1 items-center justify-center flex-col">
      <div className="text-primary-200 text-xl">Game will be here</div>
      {Array.from(state.joinedPeers).map(([_key, peer]) => {
        return (
          <div className="text-primary-100">{`${peer.nickname} is here`}</div>
        );
      })}
      {!isJoined ? (
        <button
          onClick={() => joinButtonClicked()}
          className="bg-secondary mt-3 text-primary-100 p-3 font-bold rounded-md shadow-md hover:bg-secondary-hover !isJoined);"
        >
          JOIN ROUND
        </button>
      ) : (
        <button
          onClick={() => joinButtonClicked()}
          className="bg-ternary mt-3 text-primary-100 p-3 font-bold rounded-md shadow-md hover:bg-ternary-hover !isJoined);"
        >
          LEAVE ROUND
        </button>
      )}
    </div>
  );
};
