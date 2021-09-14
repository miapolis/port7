import create from "zustand";
import { Peer } from "@port7/dock/lib/games/rumble";

interface RumbleState {
  landed: boolean;
  milestone: string | undefined;
  joinedPeers: Map<number, Peer>;
  serverToLocalNow: number | undefined;
  startTimestamp: number | undefined;
  doLanding: () => void;
  setMilestone: (milestone: string) => void;
  setServerNow: (serverNow: number) => void;
  setStartTimestamp: (timestamp: number | undefined) => void;
  setJoinedPeers: (peers: Peer[]) => void;
  addJoinedPeer: (id: number, nickname: string) => void;
  removeJoinedPeer: (id: number) => void;
}

export const useRumbleStore = create<RumbleState>((set) => ({
  landed: false,
  milestone: undefined,
  joinedPeers: new Map<number, Peer>(),
  serverToLocalNow: undefined,
  startTimestamp: undefined,
  doLanding: () => {
    set((_state) => ({
      landed: true,
    }));
  },
  setMilestone: (milestone: string) => {
    set((_state) => ({
      milestone: milestone
    }));
  },
  setServerNow: (serverNow: number) => {
    set((_state) => ({
      serverToLocalNow: Date.now() - serverNow,
    }));
  },
  setStartTimestamp: (timestamp: number | undefined) => {
    set((_state) => ({
      startTimestamp: timestamp,
    }));
  },
  setJoinedPeers: (peers: Peer[]) => {
    set((_state) => {
      const mapped = new Map(peers.map((obj) => [obj.id, obj]));
      return { joinedPeers: mapped };
    });
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
