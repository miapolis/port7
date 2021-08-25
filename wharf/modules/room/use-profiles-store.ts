import create from "zustand";
import { ManagedPeer } from "@port7/dock/lib";

interface ProfilesState {
  profiles: ManagedPeer[];
  setProfiles: (profiles: ManagedPeer[]) => void;
}

export const useProfilesStore = create<ProfilesState>((set) => ({
  profiles: [],
  setProfiles: (profiles: ManagedPeer[]) => {
    set((_state) => ({
      profiles: profiles,
    }));
  },
}));
