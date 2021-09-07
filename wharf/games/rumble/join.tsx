import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "./use-rumble-store";
import { secondsLeft } from "./util/time";
import { me } from "@port7/modules/room/use-room-store";
import { Button } from "@port7/ui/button";

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

  const [startTimerInterval, setStartTimerInterval] = React.useState<
    NodeJS.Timer | undefined
  >();
  const [secondsToStart, setSecondsToStart] = React.useState<
    number | undefined
  >();

  React.useEffect(() => {
    if (!state.startTimestamp || !state.serverToLocalNow) {
      if (startTimerInterval) clearInterval(startTimerInterval);
      setSecondsToStart(undefined);
      return;
    }

    const func = () => {
      if (!state.startTimestamp || !state.serverToLocalNow) return;
      const seconds = secondsLeft(
        state.startTimestamp + state.serverToLocalNow
      );
      setSecondsToStart(seconds);
    };

    setStartTimerInterval(
      setInterval(() => {
        func();
      }, 50)
    );
    func();
  }, [state.startTimestamp]);

  return (
    <div className="flex flex-1 items-center justify-center flex-col">
      <div className="w-96 h-96 bg-primary-700 rounded-full flex items-center justify-center flex-col shadow-xl">
        <div className="text-primary-100 text-2xl">No one is here yet</div>
        <div className="text-primary-200 text-xl mb-4">
          Click the join button below
        </div>
        <Button color="secondary" padding="large">JOIN ROUND</Button>
      </div>
      {/* {secondsToStart ? (
        <div className="mb-10 text-primary-100">
          {`Round will start in ${secondsToStart}s`}
        </div>
      ) : null}
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
      )} */}
    </div>
  );
};
