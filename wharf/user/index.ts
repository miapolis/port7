import { KEY_NICKNAME, KEY_IS_PREFERRED_NICKNAME } from "../lib/local-storage";

export type User = {
  nickname: string;
  isPreferredNickname: boolean;
};

export const doInitialUser = (): User => {
  let currentNickname = localStorage.getItem(KEY_NICKNAME);
  let isPreferredRaw = localStorage.getItem(KEY_IS_PREFERRED_NICKNAME);
  let isPreferred = isPreferredRaw ? rawToBool(isPreferredRaw) : false;

  if (!currentNickname || !isPreferredRaw) {
    currentNickname = generateGuestName();
    isPreferred = false;
    localStorage.setItem(KEY_NICKNAME, currentNickname);
    localStorage.setItem(KEY_IS_PREFERRED_NICKNAME, "false");
  }

  return {
    nickname: currentNickname,
    isPreferredNickname: isPreferred,
  };
};

export const setPreferredNickname = (nickname: string) => {
  localStorage.setItem(KEY_NICKNAME, nickname);
  if (!rawToBool(localStorage.getItem(KEY_IS_PREFERRED_NICKNAME) ?? "")) {
    localStorage.setItem(KEY_IS_PREFERRED_NICKNAME, "true");
  }
};

const generateGuestName = (): string => {
  let tag: string = "";
  for (let i = 0; i < 4; i++) {
    tag += Math.floor(Math.random() * 10).toString();
  }
  return `Guest${tag}`;
};

const rawToBool = (raw: string): boolean => {
  switch (raw) {
    case "false":
      return false;
    case "true":
      return true;
    default:
      return false;
  }
};

export * from "./use-user-store";
