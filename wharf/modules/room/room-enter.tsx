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
  const roomStore = useRoomStore();

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

  if (roomStore && roomStore.dcReason) {
    return (
      <div className="w-full h-full flex items-center justify-center">
        <div className="flex flex-col m-auto items-center">
          <div className="text-5xl font-bold text-primary-200 mb-4">
            DISCONNECTED
          </div>
          <div className="text-2xl text-primary-100">
            {roomStore.dcReason === "kick"
              ? "You have been kicked"
              : "You have been disconnected"}
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};
