import React from "react";
import { useConn } from "@port7/hooks/use-conn";
import { useRumbleStore } from "../../use-rumble-store";
import { secondsLeft } from "../../util/time";
import { JoinTable } from "./join-table";
import { iAmJoined } from "../../i-am-joined";

export const Join = () => {
  const conn = useConn();
  const state = useRumbleStore();
  const joined = iAmJoined();

  const joinButtonClicked = async () => {
    if (!joined) {
      conn?.sendCast("rumble:join_round", {});
    } else {
      conn?.sendCast("rumble:leave_round", {});
    }
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
    if (startTimerInterval) clearInterval(startTimerInterval);
    if (!state.startTimestamp || !state.serverToLocalNow) {
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
            isJoined={joined}
            secondsToStart={secondsToStart || 15}
            onJoinClick={joinButtonClicked}
          />
        </div>
      ) : null}
    </div>
  );
};
