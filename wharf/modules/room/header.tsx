import React from "react";
import { useRoomStore } from "./use-room-store";

import CloseRoundedIcon from "@material-ui/icons/CloseRounded";
import MenuOpenRoundedIcon from "@material-ui/icons/MenuOpenRounded";

export interface HeaderProps {
  chatOpen: boolean;
  onChatOpenToggel?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  chatOpen,
  onChatOpenToggel,
}) => {
  const room = useRoomStore().room;
  if (!room) return null;

  return (
    <div className="w-full h-12 top-0 bg-primary-700 flex items-center px-2 shadow-md z-10 relative">
      <div className="text-primary-300 text-xl">{`${room.name}${
        !room.isPrivate ? " | " + room.code : ""
      }`}</div>
      <div className="absolute right-0 h-full">
        <div className="h-full w-12 flex items-center justify-center">
          {chatOpen ? (
            <CloseRoundedIcon style={{ color: "#dee3ea" }} />
          ) : (
            <MenuOpenRoundedIcon style={{ color: "#dee3ea" }} />
          )}
        </div>
        <div
          className="absolute w-full h-full transition duration-200 top-0 bg-primary-100 opacity-0 hover:opacity-10"
          onClick={() => (onChatOpenToggel ? onChatOpenToggel() : {})}
        ></div>
      </div>
    </div>
  );
};
