import React from "react";
import { WsHandlerProvider } from "./use-ws-handler";
import { WaitForLanding } from "./wait-for-landing";
import { Join } from "./views/join";
import { useRumbleStore } from "./use-rumble-store";
import { Game } from "./views/game";

export const Rumble: React.FC = () => {
  const milestone = useRumbleStore().milestone;

  return (
    <div className="w-full min-w-0 h-full flex flex-shrink">
      <WsHandlerProvider>
        <WaitForLanding>
          {milestone?.state === "lobby" ? (
            <Join />
          ) : milestone?.state === "game" ? (
            <Game />
          ) : (
            <div>{milestone?.state.toString()}</div>
          )}
        </WaitForLanding>
      </WsHandlerProvider>
    </div>
  );
};
