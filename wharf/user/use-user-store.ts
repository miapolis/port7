import create from "zustand";
import { User } from "./index";

interface UserState {
  user: User | undefined;
  setUser: (nickname: string, isPreferred: boolean) => void;
}

export const useUserStore = create<UserState>((set) => ({
  user: undefined,
  setUser: (nickname: string, isPreferred: boolean) => {
    set((_state) => ({
      user: {
        nickname: nickname,
        isPreferredNickname: isPreferred,
      },
    }));
  },
}));
