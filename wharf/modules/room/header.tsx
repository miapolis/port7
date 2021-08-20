import React from "react";
import { useRoomStore } from "./use-room-store";

export const Header: React.FC = () => {
  const room = useRoomStore().room;
  if (!room) return null;

  return (
    <div className="w-full h-10 top-0 bg-primary-700 flex items-center px-2 shadow-md z-10">
      <div className="text-primary-300 text-xl">{`${room.name}${
        !room.isPrivate ? " | " + room.code : ""
      }`}</div>
    </div>
  );
};
