import create from "zustand";
import { Peer } from "@port7/dock/lib/games/rumble";

interface RumbleState {
  landed: boolean;
  joinedPeers: Map<number, Peer>;
  doLanding: () => void;
  setJoinedPeers: (peers: Peer[]) => void;
  addJoinedPeer: (id: number, nickname: string) => void;
  removeJoinedPeer: (id: number) => void;
}

export const useRumbleStore = create<RumbleState>((set) => ({
  landed: false,
  joinedPeers: new Map<number, Peer>(),
  doLanding: () => {
    set((_state) => ({
      landed: true,
    }));
  },
  setJoinedPeers: (peers: Peer[]) => {
    set((_state) => ({
      joinedPeers: new Map(peers.map((obj) => [obj.id, obj])),
    }));
  },
  addJoinedPeer: (id: number, nickname: string) => {
    set((state) => ({
      joinedPeers: state.joinedPeers.set(id, {
        id,
        nickname,
        isDisconnected: false,
      }),
    }));
  },
  removeJoinedPeer: (id: number) => {
    set((state) => {
      state.joinedPeers.delete(id);
      return {
        joinedPeers: state.joinedPeers,
      };
    });
  },
}));
