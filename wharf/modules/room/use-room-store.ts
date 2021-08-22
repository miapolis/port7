import create from "zustand";
import { Peer, Room } from "@port7/dock/lib";

interface RoomState {
  room: Room | undefined;
  peers: Map<number, Peer>;
  setRoom: (room: Room | undefined) => void;
  setPeers: (peer: Peer[]) => void;
  addPeer: (id: number, nickname: string) => void;
  disconnectPeer: (id: number) => void;
  removePeer: (id: number) => void;
}

export const useRoomStore = create<RoomState>((set) => ({
  room: undefined,
  peers: new Map(),
  setRoom: (room: Room | undefined) => {
    set((_state) => ({
      room: room,
    }));
  },
  setPeers: (peers: Peer[]) => {
    set((_state) => ({
      peers: new Map(peers.map((obj) => [obj.id, obj])),
    }));
  },
  addPeer: (id: number, nickname: string) => {
    set((state) => ({
      peers: state.peers.set(id, { id, nickname, isDisconnected: false }),
    }));
  },
  disconnectPeer: (id: number) => {
    set((state) => {
      const peer = state.peers.get(id);
      return {
        peers: state.peers.set(id, {
          id,
          nickname: peer?.nickname || "",
          isDisconnected: true,
        }),
      };
    });
  },
  removePeer: (id: number) => {
    set((state) => {
      state.peers.delete(id);
      return {
        peers: state.peers,
      };
    });
  },
}));
