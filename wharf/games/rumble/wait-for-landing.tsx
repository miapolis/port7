import React from "react";
import { me } from "@port7/modules/room/use-room-store";
import { useRumbleStore } from "./use-rumble-store";

export const WaitForLanding: React.FC = ({ children }) => {
  if (!useRumbleStore().landed) return <></>;
  if (!me()) return <></>;

  return <>{children}</>;
};
