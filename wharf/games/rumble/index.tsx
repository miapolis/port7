import React from "react";
import { WsHandlerProvider } from "./use-ws-handler";
import { WaitForLanding } from "./wait-for-landing";
import { Join } from "./views/join";
import { useRumbleStore } from "./use-rumble-store";
import { Game } from "./views/game";

export const Rumble: React.FC = () => {
  const milestone = useRumbleStore().milestone;

  return (
    <div className="w-full h-full flex">
      <WsHandlerProvider>
        <WaitForLanding>
          {milestone === "lobby" ? (
            <Join />
          ) : milestone === "game" ? (
            <Game />
          ) : (
            ""
          )}
        </WaitForLanding>
      </WsHandlerProvider>
    </div>
  );
};
