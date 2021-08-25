import React from "react";
import { Room } from "@port7/dock/lib";
import { useConn } from "@port7/hooks/use-conn";
import { useRoomStore } from "./use-room-store";
import { useUserStore } from "@port7/user";

export interface RoomEnterProps {
  room: Room;
}

export const RoomEnter: React.FC<RoomEnterProps> = ({ room, children }) => {
  const conn = useConn();

  React.useEffect(() => {
    const func = async () => {
      let { data }: any = await conn?.sendCall("room:join", {
        roomId: room.id,
      });
      let nickname = useUserStore.getState().user?.nickname ?? "";
      useRoomStore.getState().setPeers(data.peers);
      useRoomStore.getState().addPeer(data.myPeerId, nickname, data.myRoles);
      useRoomStore.getState().setMyPeerId(data.myPeerId);
    };
    func();
  }, []);

  return <>{children}</>;
};
