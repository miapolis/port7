import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "./use-rumble-store";
import { secondsLeft } from "./util/time";
import { me } from "@port7/modules/room/use-room-store";
import { JoinTable } from "./join-table";

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

  const [tableScale, setTableScale] = React.useState<number | undefined>();
  const [startTimerInterval, setStartTimerInterval] = React.useState<
    NodeJS.Timer | undefined
  >();
  const [secondsToStart, setSecondsToStart] = React.useState<
    number | undefined
  >();

  const calcScale = () => {
    const width = window.innerWidth;
    setTableScale(Math.min(1, width / 700));
  };

  React.useEffect(() => {
    calcScale();
    window.addEventListener("resize", () => {
      calcScale();
    });
  }, []);

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
      {tableScale ? (
        <div style={{ transform: `scale(${tableScale})` }}>
          <JoinTable
            isJoined={isJoined}
            secondsToStart={secondsToStart || 15}
            onJoinClick={joinButtonClicked}
          />
        </div>
      ) : null}
    </div>
  );
};
