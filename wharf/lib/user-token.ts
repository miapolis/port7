import { KEY_USER_TOKEN } from "./local-storage";

export const getUserToken = (): string => {
  const existing = localStorage.getItem(KEY_USER_TOKEN);
  if (existing != null && existing.length == 16) return existing;

  let token = "";
  const characters =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-";
  const length = characters.length;
  for (let i = 0; i < 16; i++) {
    token += characters.charAt(Math.floor(Math.random() * length));
  }

  localStorage.setItem(KEY_USER_TOKEN, token);
  return token;
};
