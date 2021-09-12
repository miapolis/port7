import { me } from "@port7/modules/room/use-room-store";
import { useRumbleStore } from "./use-rumble-store";

export const iAmJoined = (): boolean => {
  const self = me();

  return Array.from(useRumbleStore.getState().joinedPeers.values() || [])
    .map((x) => x.id)
    .includes(self.id);
};
