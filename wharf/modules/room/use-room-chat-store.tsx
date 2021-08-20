import create from "zustand";
import { combine } from "zustand/middleware";

interface TextToken {
  t: "text";
  v: string;
}

interface LinkToken {
  t: "link"
  v: string;
}

export type RoomChatMessageToken = TextToken | LinkToken;

export interface RoomChatMessage {
  id: string;
  from: string;
  sentAt: string;
  nickname: string;
  tokens: RoomChatMessageToken[];
}

export const useRoomChatStore = create(
  combine(
    {
      messages: [] as RoomChatMessage[],
    },
    (set) => ({
      addMessage: (m: RoomChatMessage) =>
        set((s) => ({
          messages: [
            { ...m },
            ...(s.messages.length <= 100
              ? s.messages
              : s.messages.slice(0, 100)),
          ],
        })),
    })
  )
);

// TODO: this should probably go somewhere else
export const createSystemMessage = (text: string): RoomChatMessage => {
  return {
    id: text,
    from: "system",
    sentAt: "",
    nickname: "system", // Fix
    tokens: [{t: "text", v: text}]
  }
}
