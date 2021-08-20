import React from "react";
import { Room } from "@port7/dock/lib";
import { useConn } from "@port7/hooks/use-conn";

export interface RoomEnterProps {
  room: Room;
}

export const RoomEnter: React.FC<RoomEnterProps> = ({ room, children }) => {
  const conn = useConn();

  React.useEffect(() => {
    conn?.sendCall("room:join", { roomId: room.id });
  }, []);

  return <>{children}</>;
};
