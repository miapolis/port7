import create from "zustand";
import { Room } from "@port7/dock/lib";

interface RoomState {
  room: Room | undefined;
  setRoom: (room: Room | undefined) => void;
  addPeer: (id: number, nickname: string) => void;
  removePeer: (id: number) => void;
}

export const useRoomStore = create<RoomState>((set) => ({
  room: undefined,
  setRoom: (room: Room | undefined) => {
    set((_state) => ({
      room: room,
    }));
  },
  addPeer: (id: number, nickname: string) => {
    set((state) => ({
      room: state.room
        ? {
            ...state.room,
            peers: state.room.peers.concat({ id: id, nickname: nickname }),
          }
        : undefined,
    }));
  },
  removePeer: (id: number) => {
    set((state) => ({
      room: state.room
        ? {
            ...state.room,
            peers: state.room.peers.filter((x) => x.id !== id),
          }
        : undefined,
    }));
  },
}));
