import create from "zustand";
import { combine } from "zustand/middleware";
import { v4 as uuidv4 } from "uuid";

interface TextToken {
  t: "text";
  v: string;
}

interface LinkToken {
  t: "link";
  v: string;
}

export type RoomChatMessageToken = TextToken | LinkToken;

export interface RoomChatMessage {
  id: string;
  from: string;
  sentAt: string;
  nickname: string;
  tokens: RoomChatMessageToken[];
  isSystem: boolean;
}

export const useRoomChatStore = create(
  combine(
    {
      messages: [] as RoomChatMessage[],
      isRoomChatScrolledToTop: false,
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
      setIsRoomChatScrolledToTop: (isRoomChatScrolledToTop: boolean) =>
        set({
          isRoomChatScrolledToTop,
        }),
    })
  )
);

// TODO: this should probably go somewhere else
export const createSystemMessage = (text: string): RoomChatMessage => {
  console.log("Creating system message...");
  return {
    id: uuidv4(),
    isSystem: true,
    from: "",
    sentAt: "",
    nickname: "",
    tokens: [{ t: "text", v: text }],
  };
};
