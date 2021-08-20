import create from "zustand";
import { Room } from "@port7/dock/lib";

interface RoomState {
  room: Room | undefined;
  setRoom: (room: Room | undefined) => void;
}

export const useRoomStore = create<RoomState>((set) => ({
  room: undefined,
  setRoom: (room: Room | undefined) => {
    set((_state) => ({
      room: room,
    }));
  },
}));
