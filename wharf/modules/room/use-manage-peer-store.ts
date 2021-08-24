import { ManagedPeer } from "@port7/dock/lib";
import create from "zustand";

interface PeerState {
  peer: ManagedPeer | undefined;
  setPeer: (peer: ManagedPeer) => void;
  clear: () => void;
}

export const useManagePeerStore = create<PeerState>((set) => ({
  peer: undefined,
  setPeer: (peer: ManagedPeer) => {
    set((_state) => ({
      peer: peer
    }))
  },
  clear: () => {
    set((_state) => ({
      peer: undefined,
    }))
  }
}));
