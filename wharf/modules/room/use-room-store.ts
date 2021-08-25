import create from "zustand";
import { Peer, Role, Room } from "@port7/dock/lib";

interface RoomState {
  room: Room | undefined;
  myPeerId: number;
  peers: Map<number, Peer>;
  setRoom: (room: Room | undefined) => void;
  setMyPeerId: (id: number) => void;
  setPeers: (peer: Peer[]) => void;
  addPeer: (id: number, nickname: string, roles: Role[]) => void;
  disconnectPeer: (id: number) => void;
  removePeer: (id: number) => void;
}

export const useRoomStore = create<RoomState>((set) => ({
  room: undefined,
  myPeerId: -1,
  peers: new Map(),
  setRoom: (room: Room | undefined) => {
    set((_state) => ({
      room: room,
    }));
  },
  setMyPeerId: (id: number) => {
    set((_state) => ({
      myPeerId: id,
    }));
  },
  setPeers: (peers: Peer[]) => {
    set((_state) => ({
      peers: new Map(peers.map((obj) => [obj.id, obj])),
    }));
  },
  addPeer: (id: number, nickname: string, roles: Role[]) => {
    set((state) => ({
      peers: state.peers.set(id, { id, nickname, isDisconnected: false, roles: roles}),
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
          roles: peer?.roles || []
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

export const me = (): Peer => {
  const myId = useRoomStore.getState().myPeerId;
  return useRoomStore.getState().peers.get(myId) as Peer;
};
