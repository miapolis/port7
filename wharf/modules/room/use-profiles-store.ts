import create from "zustand";
import { ManagedPeer } from "@port7/dock/lib";

interface ProfilesState {
  profiles: ManagedPeer[];
  shouldUpdate: boolean;
  setProfiles: (profiles: ManagedPeer[]) => void;
  triggerUpdate: () => void;
  endUpdate: () => void;
}

export const useProfilesStore = create<ProfilesState>((set) => ({
  profiles: [],
  shouldUpdate: false,
  setProfiles: (profiles: ManagedPeer[]) => {
    set((_state) => ({
      profiles: profiles,
    }));
  },
  triggerUpdate: () => {
    set((_state) => ({
      shouldUpdate: true,
    }));
  },
  endUpdate: () => {
    set((_state) => ({
      shouldUpdate: false,
    }));
  },
}));
