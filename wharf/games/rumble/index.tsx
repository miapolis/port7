import React from "react";
import { WsHandlerProvider } from "./use-ws-handler";
import { WaitForLanding } from "./wait-for-landing";
import { Join } from "./join";

export const Rumble: React.FC = () => {
  return (
    <div className="w-full h-full flex">

    <WsHandlerProvider>
      <WaitForLanding>
        <Join />
      </WaitForLanding>
    </WsHandlerProvider>
    </div>
  );
};
