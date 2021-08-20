import React from "react";
import { WebSocketContext } from "../modules/ws/ws-provider";
import { useRoomChatStore, createSystemMessage } from "../modules/room/use-room-chat-store";

export const useMainWsHandler = () => {
  const { conn } = React.useContext(WebSocketContext);

  React.useEffect(() => {
    if (!conn) return;

    const unsubs = [
      conn.addListener("user_join", ({data}: any) => {
        useRoomChatStore.getState().addMessage(createSystemMessage(`${data.user.nickname} joined.`));
      }),
      conn.addListener("chat:send", ({ data }: any) => {
        useRoomChatStore.getState().addMessage(data)
      }),
    ];

    return () => {
      unsubs.forEach((u) => u());
    };
  }, [conn]);
};

export const MainWsHandlerProvider: React.FC = ({ children }) => {
  useMainWsHandler();
  return <>{children}</>;
};
